#!/usr/bin/env bun
// Bumps the digest of every digest-pinned image (including sidecars) in a
// chart's deployment template to the current upstream.
//
// Usage:
//   bun scripts/bump-image.ts <chart>    bump one chart (top-level + sidecars)
//   bun scripts/bump-image.ts --all      bump every digest-pinned chart
//   bun scripts/bump-image.ts --check    report only, exit 1 if anything is stale
//
// Discovers images by scanning k8s/charts/*/templates/deployment.yaml for
// any `image:` line whose reference is already digest-pinned (`@sha256:`).
// Floating tags are skipped — they don't need bumping.
//
// Private registries that need credentials are skipped here too — `skopeo
// inspect --no-creds` can't reach them. Bump those via their own recipe
// (e.g. `just bump-tranquil` for atcr.io).

import { $ } from "bun";

const GLOB = "k8s/charts/*/templates/deployment.yaml";
const IMAGE_RE = /image:\s+(\S+?):(\S+?)@(sha256:[a-f0-9]+)/g;
const PRIVATE_REGISTRIES = ["atcr.io/"];

type PinnedImage = {
  chartName: string;
  templatePath: string;
  repository: string;
  floatTag: string;
  currentDigest: string;
};

function chartNameFromPath(templatePath: string): string {
  return templatePath.split("/")[2];
}

const privateRegistryCharts = new Set<string>();

async function discoverPinnedImages(): Promise<PinnedImage[]> {
  const glob = new Bun.Glob(GLOB);
  const pinned: PinnedImage[] = [];

  for await (const templatePath of glob.scan(".")) {
    const chartName = chartNameFromPath(templatePath);
    const text = await Bun.file(templatePath).text();

    for (const match of text.matchAll(IMAGE_RE)) {
      const repository = match[1];
      const floatTag = match[2];
      const currentDigest = match[3];

      if (PRIVATE_REGISTRIES.some((r) => repository.startsWith(r))) {
        privateRegistryCharts.add(chartName);
        continue;
      }

      pinned.push({
        chartName,
        templatePath,
        repository,
        floatTag,
        currentDigest,
      });
    }
  }

  return pinned;
}

async function fetchUpstreamDigest(
  repository: string,
  floatTag: string,
): Promise<string> {
  const result = await $`
    skopeo inspect --no-creds docker://${repository}:${floatTag} --format ${"{{.Digest}}"}
  `
    .quiet()
    .nothrow();
  if (result.exitCode !== 0) {
    throw new Error(
      `skopeo failed for ${repository}:${floatTag}: ${result.stderr.toString().trim()}`,
    );
  }
  return result.stdout.toString().trim();
}

function label(image: PinnedImage): string {
  const short = image.repository.split("/").slice(-1)[0];
  return `${image.chartName} (${short})`;
}

async function bumpImage(image: PinnedImage, write: boolean): Promise<boolean> {
  const upstream = await fetchUpstreamDigest(image.repository, image.floatTag);
  if (upstream === image.currentDigest) {
    console.log(`${label(image)}: ✓ up to date`);
    return false;
  }

  console.log(
    `${label(image)}: ${image.currentDigest.slice(7, 19)} → ${upstream.slice(7, 19)}`,
  );

  if (write) {
    const text = await Bun.file(image.templatePath).text();
    const updated = text.replace(image.currentDigest, upstream);
    await Bun.write(image.templatePath, updated);
  }
  return true;
}

// --- main ---

const arg = process.argv[2];
if (!arg || arg === "-h" || arg === "--help") {
  console.error("usage: bump-image.ts <chart> | --all | --check");
  process.exit(2);
}

const allImages = await discoverPinnedImages();

let imagesToBump: PinnedImage[];
let shouldWrite = true;

if (arg === "--all") {
  imagesToBump = allImages;
} else if (arg === "--check") {
  imagesToBump = allImages;
  shouldWrite = false;
} else {
  imagesToBump = allImages.filter((image) => image.chartName === arg);
  if (imagesToBump.length === 0) {
    if (privateRegistryCharts.has(arg)) {
      console.error(
        `${arg} is on a private registry; use its dedicated recipe (e.g. \`just bump-tranquil\`)`,
      );
      process.exit(1);
    }
    console.error(`no chart '${arg}' with a digest-pinned image`);
    process.exit(1);
  }
}

let staleCount = 0;
for (const image of imagesToBump) {
  const wasStale = await bumpImage(image, shouldWrite);
  if (wasStale) staleCount++;
}

if (arg === "--check" && staleCount > 0) {
  console.error(`\n${staleCount} image(s) stale`);
  process.exit(1);
}

#!/usr/bin/env bun
// Bumps the digest of every digest-pinned image (including sidecars) in a
// chart's values.yaml to the current upstream.
//
// Usage:
//   bun scripts/bump-image.ts <chart>    bump one chart (top-level + sidecars)
//   bun scripts/bump-image.ts --all      bump every digest-pinned chart
//   bun scripts/bump-image.ts --check    report only, exit 1 if anything is stale
//
// Discovers images by walking each chart's values.yaml for any `image:` block
// with `repository` and `tag` fields, then keeps only the ones whose tag
// already contains `@sha256:` (i.e. is digest-pinned). Floating tags are
// skipped — they don't need bumping.
//
// Private registries that need credentials are skipped here too — `skopeo
// inspect --no-creds` can't reach them. Bump those via their own recipe
// (e.g. `just bump-tranquil` for atcr.io).

import { $ } from "bun";

const PRIVATE_REGISTRIES = ["atcr.io/"];

type PinnedImage = {
  chartName: string;
  valuesPath: string;
  imagePath: string; // dotted path like "image" or "rclone.image"
  repository: string;
  floatTag: string; // e.g. "15", "latest", "1.71"
  currentDigest: string; // e.g. "sha256:abc..."
};

function chartNameFromPath(valuesPath: string): string {
  return valuesPath.split("/")[2];
}

// Walks a parsed YAML tree and yields every `image: {repository, tag}` block.
function* findImageBlocks(
  node: unknown,
  pathSegments: string[] = [],
): Generator<{ path: string; repository: string; tag: string }> {
  if (!node || typeof node !== "object") return;

  if (Array.isArray(node)) {
    for (let i = 0; i < node.length; i++) {
      yield* findImageBlocks(node[i], [...pathSegments, `[${i}]`]);
    }
    return;
  }

  for (const [key, value] of Object.entries(node as Record<string, unknown>)) {
    if (key === "image" && value && typeof value === "object") {
      const repository = (value as { repository?: unknown }).repository;
      const tag = (value as { tag?: unknown }).tag;
      if (
        typeof repository === "string" &&
        (typeof tag === "string" || typeof tag === "number")
      ) {
        yield {
          path: [...pathSegments, "image"].join("."),
          repository,
          tag: String(tag),
        };
      }
    }
    yield* findImageBlocks(value, [...pathSegments, key]);
  }
}

const privateRegistryCharts = new Set<string>();

async function discoverPinnedImages(): Promise<PinnedImage[]> {
  const glob = new Bun.Glob("k8s/charts/*/values.yaml");
  const pinned: PinnedImage[] = [];

  for await (const valuesPath of glob.scan(".")) {
    const values = Bun.YAML.parse(await Bun.file(valuesPath).text());
    const chartName = chartNameFromPath(valuesPath);

    for (const block of findImageBlocks(values)) {
      const [floatTag, digestHex] = block.tag.split("@sha256:");
      if (!digestHex) continue; // floating tag, skip
      if (PRIVATE_REGISTRIES.some((r) => block.repository.startsWith(r))) {
        privateRegistryCharts.add(chartName);
        continue;
      }

      pinned.push({
        chartName,
        valuesPath,
        imagePath: block.path,
        repository: block.repository,
        floatTag,
        currentDigest: `sha256:${digestHex}`,
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
  // Top-level images are unsurprising; for sidecars, include the dotted path.
  return image.imagePath === "image"
    ? image.chartName
    : `${image.chartName}/${image.imagePath}`;
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
    const text = await Bun.file(image.valuesPath).text();
    const updated = text.replace(image.currentDigest, upstream);
    await Bun.write(image.valuesPath, updated);
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

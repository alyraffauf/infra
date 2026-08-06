#!/usr/bin/env bun
// Bumps the digest of every digest-pinned image (including sidecars) in a
// Helm chart or raw Flux workload manifest to the current upstream.
//
// Usage:
//   bun scripts/bump-image.ts <workload> bump one workload (top-level + sidecars)
//   bun scripts/bump-image.ts --all      bump every public digest-pinned workload
//   bun scripts/bump-image.ts --check    report only, exit 1 if anything is stale
//
// Discovers direct image references in local Helm templates and raw Flux
// workload manifests. Floating tags are skipped — they don't need bumping.
//
// Private registries that need credentials are skipped here too — `skopeo
// inspect --no-creds` can't reach them. Bump those via their own recipe
// (e.g. `just bump-tranquil` for atcr.io).

import { $ } from "bun";

const MANIFEST_GLOBS = [
  "k8s/charts/*/templates/**/*.yaml",
  "k8s/flux/apps/*/**/*.yaml",
  "k8s/flux/platform/*/**/*.yaml",
];
const IMAGE_RE = /image:\s+(\S+?):(\S+?)@(sha256:[a-f0-9]+)/g;
const PRIVATE_REGISTRIES = ["atcr.io/"];

type PinnedImage = {
  workloadName: string;
  manifestPath: string;
  repository: string;
  floatTag: string;
  currentDigest: string;
};

function workloadNameFromPath(manifestPath: string): string {
  const pathSegments = manifestPath.split("/");
  if (pathSegments[1] === "charts") return pathSegments[2];
  return pathSegments[3];
}

const privateRegistryWorkloads = new Set<string>();

async function discoverPinnedImages(): Promise<PinnedImage[]> {
  const pinned: PinnedImage[] = [];

  for (const manifestGlob of MANIFEST_GLOBS) {
    const glob = new Bun.Glob(manifestGlob);
    for await (const manifestPath of glob.scan(".")) {
      const workloadName = workloadNameFromPath(manifestPath);
      const text = await Bun.file(manifestPath).text();

      for (const match of text.matchAll(IMAGE_RE)) {
        const repository = match[1];
        const floatTag = match[2];
        const currentDigest = match[3];

        if (
          PRIVATE_REGISTRIES.some((registry) => repository.startsWith(registry))
        ) {
          privateRegistryWorkloads.add(workloadName);
          continue;
        }

        pinned.push({
          workloadName,
          manifestPath,
          repository,
          floatTag,
          currentDigest,
        });
      }
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
  return `${image.workloadName} (${short})`;
}

function shortDigest(digest: string): string {
  return digest.slice(7, 19);
}

async function bumpImage(
  image: PinnedImage,
  write: boolean,
  commitEach: boolean,
): Promise<boolean> {
  const upstream = await fetchUpstreamDigest(image.repository, image.floatTag);
  if (upstream === image.currentDigest) {
    console.log(`${label(image)}: ✓ up to date`);
    return false;
  }

  const before = shortDigest(image.currentDigest);
  const after = shortDigest(upstream);

  console.log(`${label(image)}: ${before} → ${after}`);

  if (write) {
    const text = await Bun.file(image.manifestPath).text();
    const updated = text.replace(image.currentDigest, upstream);
    await Bun.write(image.manifestPath, updated);

    if (commitEach) {
      const short = image.repository.split("/").slice(-1)[0];
      const msg = `k8s/${image.workloadName} (${short}): ${image.floatTag}@${before} → ${image.floatTag}@${after}`;
      await $`git add ${image.manifestPath}`;
      await $`git commit -m ${msg}`;
    }
  }
  return true;
}

// --- main ---

const arg = process.argv[2];
if (!arg || arg === "-h" || arg === "--help") {
  console.error("usage: bump-image.ts <workload> | --all | --check");
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
  imagesToBump = allImages.filter((image) => image.workloadName === arg);
  if (imagesToBump.length === 0) {
    if (privateRegistryWorkloads.has(arg)) {
      console.error(
        `${arg} is on a private registry; use its dedicated recipe (e.g. \`just bump-tranquil\`)`,
      );
      process.exit(1);
    }
    console.error(`no workload '${arg}' with a public digest-pinned image`);
    process.exit(1);
  }
}

const commitEach = shouldWrite;

let staleCount = 0;
for (const image of imagesToBump) {
  const wasStale = await bumpImage(image, shouldWrite, commitEach);
  if (wasStale) staleCount++;
}

if (staleCount > 0) {
  if (arg === "--check") {
    console.error(`\n${staleCount} image(s) stale`);
    process.exit(1);
  } else {
    console.log(`\n${staleCount} image(s) bumped`);
  }
}

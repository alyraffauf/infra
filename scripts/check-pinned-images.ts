// Every chart that's actually deployed must pin its image (or any sidecar
// image, like the redis or rclone sidecars) to a specific digest. Charts in
// ALLOW_FLOATING are exempt — usually because they live on a private
// registry with active dev where pinning would break the push-and-redeploy
// loop.

const HELMFILE = "k8s/helmfile.yaml";
const ALLOW_FLOATING = new Set<string>();

const DIGEST_SUFFIX = /@sha256:[0-9a-f]{64}$/;

type Release = { chart: string };
type Helmfile = { releases: Release[] };

function chartNameFromPath(valuesPath: string): string {
  // valuesPath looks like "k8s/charts/<name>/values.yaml"
  return valuesPath.split("/")[2];
}

async function deployedChartNames(): Promise<Set<string>> {
  const helmfile = Bun.YAML.parse(await Bun.file(HELMFILE).text()) as Helmfile;
  const names = new Set<string>();
  for (const release of helmfile.releases) {
    if (release.chart.startsWith("./charts/")) {
      names.add(release.chart.replace(/^\.\/charts\//, ""));
    }
  }
  return names;
}

// Walks a parsed YAML tree and returns every `image: {tag: ...}` it finds,
// along with the dotted path that gets you there (e.g. "image",
// "rclone.image"). Mirrors what renovate's helm-values manager looks for.
function findImageTags(
  node: unknown,
  pathSegments: string[] = [],
): Array<{ path: string; tag: string }> {
  if (!node || typeof node !== "object") return [];

  const found: Array<{ path: string; tag: string }> = [];

  if (Array.isArray(node)) {
    for (let i = 0; i < node.length; i++) {
      found.push(...findImageTags(node[i], [...pathSegments, `[${i}]`]));
    }
    return found;
  }

  for (const [key, value] of Object.entries(node as Record<string, unknown>)) {
    if (
      key === "image" &&
      value &&
      typeof value === "object" &&
      "tag" in value
    ) {
      const tag = (value as { tag?: unknown }).tag;
      if (tag) {
        found.push({
          path: [...pathSegments, "image"].join("."),
          tag: String(tag),
        });
      }
    }
    found.push(...findImageTags(value, [...pathSegments, key]));
  }

  return found;
}

export async function checkPinnedImages(): Promise<string[]> {
  const deployed = await deployedChartNames();
  const errors: string[] = [];

  const glob = new Bun.Glob("k8s/charts/*/values.yaml");
  for await (const valuesPath of glob.scan(".")) {
    const chartName = chartNameFromPath(valuesPath);
    if (!deployed.has(chartName)) continue;
    if (ALLOW_FLOATING.has(chartName)) continue;

    const values = Bun.YAML.parse(await Bun.file(valuesPath).text());
    for (const { path, tag } of findImageTags(values)) {
      if (!DIGEST_SUFFIX.test(tag)) {
        errors.push(
          `${chartName}: ${path}.tag '${tag}' is not pinned to a sha256 digest`,
        );
      }
    }
  }

  return errors;
}

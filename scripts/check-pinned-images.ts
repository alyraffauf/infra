// Every deployed chart must pin every container image to a sha256 digest.
// Charts in ALLOW_FLOATING are exempt — usually because they live on a
// private registry with active dev where pinning would break the
// push-and-redeploy loop.

const HELMFILE = "k8s/helmfile.yaml";
const GLOB = "k8s/charts/*/templates/deployment.yaml";
const ALLOW_FLOATING = new Set<string>();

const DIGEST_RE = /image:\s+\S+?:\S+?@(sha256:[0-9a-f]{64})/;

type Release = { chart: string };
type Helmfile = { releases: Release[] };

function chartNameFromPath(templatePath: string): string {
  return templatePath.split("/")[2];
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

async function findImageRefs(
  templatePath: string,
): Promise<Array<{ tag: string }>> {
  const text = await Bun.file(templatePath).text();
  const refs: Array<{ tag: string }> = [];

  for (const match of text.matchAll(
    /image:\s+(\S+?):(\S+?)@(sha256:[a-f0-9]*)/g,
  )) {
    refs.push({ tag: `${match[2]}@${match[3]}` });
  }

  return refs;
}

export async function checkPinnedImages(): Promise<string[]> {
  const deployed = await deployedChartNames();
  const errors: string[] = [];

  const glob = new Bun.Glob(GLOB);
  for await (const templatePath of glob.scan(".")) {
    const chartName = chartNameFromPath(templatePath);
    if (!deployed.has(chartName)) continue;
    if (ALLOW_FLOATING.has(chartName)) continue;

    const text = await Bun.file(templatePath).text();
    // Find all image: lines and check whether they contain @sha256:
    const imageLines = [...text.matchAll(/image:\s+(\S+):(\S+)/g)];
    for (const match of imageLines) {
      const fullRef = `${match[1]}:${match[2]}`;
      if (!fullRef.includes("@sha256:")) {
        const shortRepo = match[1].split("/").slice(-1)[0];
        errors.push(
          `${chartName}: ${shortRepo} '${match[2]}' is not pinned to a sha256 digest`,
        );
      }
    }
  }

  return errors;
}

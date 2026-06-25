// Every deployed chart must pin every container image to a sha256 digest.
// Charts in ALLOW_FLOATING are exempt — usually because they live on a
// private registry with active dev where pinning would break the
// push-and-redeploy loop.

const HELMFILE = "k8s/helmfile.yaml";
const GLOB = "k8s/charts/*/**/*.yaml";
const ALLOW_FLOATING = new Set<string>();

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

export async function checkPinnedImages(): Promise<string[]> {
  const deployed = await deployedChartNames();
  const errors: string[] = [];

  const glob = new Bun.Glob(GLOB);
  for await (const templatePath of glob.scan(".")) {
    const chartName = chartNameFromPath(templatePath);
    if (!deployed.has(chartName)) continue;
    if (ALLOW_FLOATING.has(chartName)) continue;

    const text = await Bun.file(templatePath).text();
    // Find concrete image refs in our local chart YAML. Template-composed refs
    // are checked where their concrete tag is defined in values.yaml.
    const imageLines = [
      ...text.matchAll(
        /^\s*(?:image|imageName):\s+["']?([^"'\s{}]+:[^"'\s{}]+)["']?\s*$/gm,
      ),
    ];
    for (const match of imageLines) {
      const fullRef = match[1];
      if (!fullRef.includes("@sha256:")) {
        const [repo, tag] = fullRef.split(":");
        const shortRepo = repo.split("/").slice(-1)[0];
        errors.push(
          `${chartName}: ${shortRepo} '${tag}' is not pinned to a sha256 digest`,
        );
      }
    }
  }

  return errors;
}

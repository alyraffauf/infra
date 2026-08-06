// Every deployed chart must pin every container image to a sha256 digest.
// Charts in ALLOW_FLOATING are exempt — usually because they live on a
// private registry with active dev where pinning would break the
// push-and-redeploy loop.

const GLOB = "k8s/charts/*/**/*.yaml";
const RAW_GLOBS = [
  "k8s/flux/apps/*/**/*.yaml",
  "k8s/flux/platform/*/**/*.yaml",
];
const FLUX_DIRS = [
  "k8s/flux/infra-crds",
  "k8s/flux/infra-core",
  "k8s/flux/platform",
  "k8s/flux/apps",
  "k8s/flux/external-routes",
];
const ALLOW_FLOATING = new Set<string>();

type HelmRelease = {
  kind?: string;
  spec?: { chart?: { spec?: { chart?: string } } };
};

function chartNameFromPath(templatePath: string): string {
  return templatePath.split("/")[2];
}

async function deployedChartNames(): Promise<Set<string>> {
  const names = new Set<string>();

  for (const dir of FLUX_DIRS) {
    const glob = new Bun.Glob(`${dir}/**/*.yaml`);
    for await (const path of glob.scan(".")) {
      const text = await Bun.file(path).text();
      for (const doc of text
        .split(/^---\s*$/m)
        .map((doc) => doc.trim())
        .filter(Boolean)) {
        const parsed = Bun.YAML.parse(doc) as HelmRelease | null;
        if (parsed?.kind !== "HelmRelease") continue;

        const chart = parsed.spec?.chart?.spec?.chart;
        if (chart?.startsWith("./k8s/charts/")) {
          names.add(chart.replace(/^\.\/k8s\/charts\//, ""));
        }
      }
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

  for (const rawGlob of RAW_GLOBS) {
    const rawFiles = new Bun.Glob(rawGlob);
    for await (const manifestPath of rawFiles.scan(".")) {
      const application = manifestPath.split("/")[3];
      if (ALLOW_FLOATING.has(application)) continue;

      const text = await Bun.file(manifestPath).text();
      const imageLines = [
        ...text.matchAll(
          /^\s*(?:image|imageName):\s+["']?([^"'\s{}]+:[^"'\s{}]+)["']?\s*$/gm,
        ),
      ];
      for (const match of imageLines) {
        const fullRef = match[1];
        if (fullRef.includes("@sha256:")) continue;

        const [repo, tag] = fullRef.split(":");
        const shortRepo = repo.split("/").slice(-1)[0];
        errors.push(
          `${application}: ${shortRepo} '${tag}' is not pinned to a sha256 digest`,
        );
      }
    }
  }

  return errors;
}

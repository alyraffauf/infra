// Every local chart is intentionally declared: production charts have at least
// one HelmRelease, while undeployed charts live in k8s/drafts. A chart may be
// used by more than one release (for example, the two Valkey instances).

const FLUX_DIRS = [
  "k8s/flux/infra-crds",
  "k8s/flux/infra-core",
  "k8s/flux/platform",
  "k8s/flux/apps",
  "k8s/flux/external-routes",
];

type HelmRelease = {
  kind?: string;
  spec?: { chart?: { spec?: { chart?: string } } };
};

function yamlDocuments(text: string): string[] {
  return text
    .split(/^---\s*$/m)
    .map((document) => document.trim())
    .filter(Boolean);
}

async function declaredChartCounts(): Promise<Map<string, number>> {
  const counts = new Map<string, number>();

  for (const directory of FLUX_DIRS) {
    const files = new Bun.Glob(`${directory}/**/*.yaml`);
    for await (const path of files.scan(".")) {
      for (const document of yamlDocuments(await Bun.file(path).text())) {
        const release = Bun.YAML.parse(document) as HelmRelease | null;
        const chart = release?.spec?.chart?.spec?.chart;
        if (
          release?.kind !== "HelmRelease" ||
          !chart?.startsWith("./k8s/charts/")
        )
          continue;

        const name = chart.slice("./k8s/charts/".length);
        counts.set(name, (counts.get(name) ?? 0) + 1);
      }
    }
  }

  return counts;
}

async function chartDirectories(root: string): Promise<Set<string>> {
  const charts = new Set<string>();
  const files = new Bun.Glob(`${root}/*/Chart.yaml`);
  for await (const path of files.scan(".")) {
    charts.add(path.split("/")[2]);
  }
  return charts;
}

export async function checkChartInventory(): Promise<string[]> {
  const [declared, production, drafts] = await Promise.all([
    declaredChartCounts(),
    chartDirectories("k8s/charts"),
    chartDirectories("k8s/drafts"),
  ]);
  const errors: string[] = [];

  for (const chart of production) {
    const count = declared.get(chart) ?? 0;
    if (count === 0)
      errors.push(
        `production chart '${chart}' has no HelmRelease; move it to k8s/drafts or deploy it`,
      );
  }

  for (const chart of drafts) {
    const count = declared.get(chart) ?? 0;
    if (count !== 0)
      errors.push(
        `draft chart '${chart}' is also deployed by ${count} HelmRelease(s)`,
      );
    if (production.has(chart))
      errors.push(`chart '${chart}' exists in both k8s/charts and k8s/drafts`);
  }

  for (const [chart, count] of declared) {
    if (!production.has(chart))
      errors.push(
        `HelmRelease references '${chart}', which is not a production chart (${count} release(s))`,
      );
  }

  return errors;
}

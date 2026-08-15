#!/usr/bin/env bun
// Render every local HelmRelease with the same global values and precedence
// Flux uses. SOPS-backed values are intentionally not read in CI.

import { join } from "node:path";

const FLUX_DIRS = [
  "k8s/flux/infra-crds",
  "k8s/flux/infra-core",
  "k8s/flux/platform",
  "k8s/flux/apps",
  "k8s/flux/external-routes",
];

// These charts use literal resource names. Keep their HelmRelease name equal
// to the chart directory so a rename cannot silently orphan or collide with
// an existing workload.
const FIXED_NAME_CHARTS = new Set([
  "morsels",
  "navidrome",
  "ombi",
  "seerr",
  "uptime-kuma",
  "vaultwarden",
]);

type HelmRelease = {
  kind?: string;
  metadata?: { name?: string };
  spec?: {
    releaseName?: string;
    targetNamespace?: string;
    chart?: { spec?: { chart?: string } };
    values?: Record<string, unknown>;
    valuesFrom?: Array<{ kind?: string; name?: string; valuesKey?: string }>;
  };
};

function yamlDocuments(text: string): string[] {
  return text
    .split(/^---\s*$/m)
    .map((document) => document.trim())
    .filter(Boolean);
}

function mergeValues(
  base: Record<string, unknown>,
  override: Record<string, unknown>,
): Record<string, unknown> {
  const merged = { ...base };
  for (const [key, value] of Object.entries(override)) {
    const existing = merged[key];
    if (
      value !== null &&
      typeof value === "object" &&
      !Array.isArray(value) &&
      existing !== null &&
      typeof existing === "object" &&
      !Array.isArray(existing)
    ) {
      merged[key] = mergeValues(
        existing as Record<string, unknown>,
        value as Record<string, unknown>,
      );
    } else {
      merged[key] = value;
    }
  }
  return merged;
}

async function localReleases(): Promise<HelmRelease[]> {
  const releases: HelmRelease[] = [];
  for (const directory of FLUX_DIRS) {
    const files = new Bun.Glob(`${directory}/**/*.yaml`);
    for await (const path of files.scan(".")) {
      for (const document of yamlDocuments(await Bun.file(path).text())) {
        const release = Bun.YAML.parse(document) as HelmRelease | null;
        const chart = release?.spec?.chart?.spec?.chart;
        if (
          release?.kind === "HelmRelease" &&
          chart?.startsWith("./k8s/charts/")
        )
          releases.push(release);
      }
    }
  }
  return releases.sort((left, right) =>
    (left.metadata?.name ?? "").localeCompare(right.metadata?.name ?? ""),
  );
}

async function run(command: string[], input?: string): Promise<void> {
  const process = Bun.spawn(command, {
    stdin: input ? new Blob([input]) : undefined,
    stdout: "inherit",
    stderr: "inherit",
  });
  if ((await process.exited) !== 0) throw new Error(command.join(" "));
}

async function commandOutput(command: string[]): Promise<string> {
  const process = Bun.spawn(command, {
    stdout: "pipe",
    stderr: "inherit",
  });
  const output = await new Response(process.stdout).text();
  if ((await process.exited) !== 0) throw new Error(command.join(" "));
  return output;
}

async function renderRelease(
  release: HelmRelease,
  globalValues: Record<string, unknown>,
): Promise<void> {
  const name = release.metadata?.name;
  const chart = release.spec?.chart?.spec?.chart;
  if (!name || !chart)
    throw new Error("HelmRelease is missing a name or chart");

  const chartName = chart.replace(/^\.\/k8s\/charts\//, "");
  if (
    FIXED_NAME_CHARTS.has(chartName) &&
    (release.spec?.releaseName ?? name) !== chartName
  ) {
    throw new Error(
      `${name}: fixed-name chart '${chartName}' must use releaseName '${chartName}'`,
    );
  }

  for (const source of release.spec?.valuesFrom ?? []) {
    if (
      source.kind !== "ConfigMap" ||
      source.name !== "cute-haus-global" ||
      source.valuesKey !== "values.yaml"
    ) {
      throw new Error(
        `${name}: renderer only supports the non-secret cute-haus-global valuesFrom source`,
      );
    }
  }

  const values = mergeValues(globalValues, release.spec?.values ?? {});
  const valuesPath = join(
    process.env.TMPDIR ?? "/tmp",
    `cute-haus-${name}-${crypto.randomUUID()}.yaml`,
  );
  await Bun.write(valuesPath, Bun.YAML.stringify(values));

  try {
    console.log(`${name}: lint and render`);
    await run(["helm", "dependency", "build", chart]);
    await run(["helm", "lint", chart, "--values", valuesPath]);

    const rendered = Bun.spawn([
      "helm",
      "template",
      release.spec?.releaseName ?? name,
      chart,
      "--namespace",
      release.spec?.targetNamespace ?? "default",
      "--values",
      valuesPath,
      "--include-crds",
    ]);
    const manifest = await new Response(rendered.stdout).text();
    if ((await rendered.exited) !== 0)
      throw new Error(`${name}: helm template`);

    await run(["kubeconform", "-ignore-missing-schemas", "-summary"], manifest);
  } finally {
    await run(["rm", "-f", valuesPath]);
  }
}

async function renderRawKustomizations(): Promise<void> {
  for (const layer of ["apps", "platform"]) {
    const files = new Bun.Glob(`k8s/flux/${layer}/*/kustomization.yaml`);
    for await (const path of files.scan(".")) {
      const directory = path.replace(/\/kustomization\.yaml$/, "");
      console.log(`${directory}: render and validate`);
      const manifest = await commandOutput(["kubectl", "kustomize", directory]);
      await run(
        ["kubeconform", "-ignore-missing-schemas", "-summary"],
        manifest,
      );
    }
  }
}

const globalValues = Bun.YAML.parse(
  await Bun.file("k8s/flux/sources/global.values.yaml").text(),
) as Record<string, unknown>;

for (const release of await localReleases()) {
  await renderRelease(release, globalValues);
}

await renderRawKustomizations();

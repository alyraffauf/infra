#!/usr/bin/env bun
// Print only Kubernetes and Flux failures. Each item includes the shortest
// useful follow-up command for the single-operator incident workflow.

type KubernetesObject = {
  kind?: string;
  metadata?: { name?: string; namespace?: string; creationTimestamp?: string };
  reason?: string;
  message?: string;
  spec?: { replicas?: number };
  status?: {
    phase?: string;
    readyReplicas?: number;
    conditions?: Array<{ type?: string; status?: string; message?: string }>;
  };
};

type KubernetesList = { items?: KubernetesObject[] };

async function kubectlJson(arguments_: string[]): Promise<KubernetesList> {
  const process = Bun.spawn(["kubectl", ...arguments_, "-o", "json"], {
    stdout: "pipe",
    stderr: "pipe",
  });
  const output = await new Response(process.stdout).text();
  const error = await new Response(process.stderr).text();
  if ((await process.exited) !== 0) throw new Error(error.trim());
  return JSON.parse(output) as KubernetesList;
}

function objectName(object: KubernetesObject): string {
  return `${object.metadata?.namespace ?? "default"}/${object.metadata?.name ?? "unknown"}`;
}

function readyCondition(object: KubernetesObject): boolean {
  return (
    object.status?.conditions?.some(
      (condition) => condition.type === "Ready" && condition.status === "True",
    ) ?? false
  );
}

function failedObjects(objects: KubernetesObject[]): KubernetesObject[] {
  return objects.filter((object) => !readyCondition(object));
}

function unhealthyWorkloads(objects: KubernetesObject[]): KubernetesObject[] {
  return objects.filter((object) => {
    if (object.kind === "StatefulSet") {
      return (
        (object.status?.readyReplicas ?? 0) !== (object.spec?.replicas ?? 1)
      );
    }
    return !object.status?.conditions?.some(
      (condition) =>
        condition.type === "Available" && condition.status === "True",
    );
  });
}

const findings: Array<{ title: string; lines: string[] }> = [];

function collectFindings(title: string, lines: string[]): boolean {
  if (lines.length === 0) return false;
  findings.push({ title, lines });
  return true;
}

let degraded = false;
try {
  const [
    kustomizations,
    releases,
    deployments,
    statefulSets,
    pvcs,
    certificates,
    events,
  ] = await Promise.all([
    kubectlJson(["get", "kustomizations.kustomize.toolkit.fluxcd.io", "-A"]),
    kubectlJson(["get", "helmreleases.helm.toolkit.fluxcd.io", "-A"]),
    kubectlJson(["get", "deployments", "-A"]),
    kubectlJson(["get", "statefulsets", "-A"]),
    kubectlJson(["get", "pvc", "-A"]),
    kubectlJson(["get", "certificates.cert-manager.io", "-A"]),
    kubectlJson([
      "get",
      "events",
      "-A",
      "--field-selector=type=Warning",
      "--sort-by=.lastTimestamp",
    ]),
  ]);

  degraded =
    collectFindings(
      "Flux Kustomizations",
      failedObjects(kustomizations.items ?? []).map(
        (object) =>
          `${objectName(object)} — flux reconcile kustomization ${object.metadata?.name} -n ${object.metadata?.namespace} --with-source`,
      ),
    ) || degraded;
  degraded =
    collectFindings(
      "Flux HelmReleases",
      failedObjects(releases.items ?? []).map(
        (object) =>
          `${objectName(object)} — flux reconcile helmrelease ${object.metadata?.name} -n ${object.metadata?.namespace} --with-source`,
      ),
    ) || degraded;
  const workloads = [
    ...(deployments.items ?? []),
    ...(statefulSets.items ?? []),
  ];
  degraded =
    collectFindings(
      "Unhealthy workloads",
      unhealthyWorkloads(workloads).map(
        (object) =>
          `${object.kind?.toLowerCase()} ${objectName(object)} — kubectl describe ${object.kind?.toLowerCase()} ${object.metadata?.name} -n ${object.metadata?.namespace}`,
      ),
    ) || degraded;
  degraded =
    collectFindings(
      "Unbound PVCs",
      (pvcs.items ?? [])
        .filter((pvc) => pvc.status?.phase !== "Bound")
        .map(
          (pvc) =>
            `${objectName(pvc)} — kubectl describe pvc ${pvc.metadata?.name} -n ${pvc.metadata?.namespace}`,
        ),
    ) || degraded;
  degraded =
    collectFindings(
      "Certificate problems",
      failedObjects(certificates.items ?? []).map(
        (certificate) =>
          `${objectName(certificate)} — kubectl describe certificate ${certificate.metadata?.name} -n ${certificate.metadata?.namespace}`,
      ),
    ) || degraded;
  collectFindings(
    "Recent warning events (do not imply current degradation)",
    (events.items ?? [])
      .slice(-20)
      .map(
        (event) =>
          `${objectName(event)} ${event.reason ?? "Warning"}: ${event.message ?? ""} — kubectl get events -A --field-selector=type=Warning --sort-by=.lastTimestamp`,
      ),
  );
} catch (error) {
  degraded = true;
  findings.push({
    title: "Kubernetes status unavailable",
    lines: [
      `${error instanceof Error ? error.message : error} — kubectl cluster-info`,
    ],
  });
}

console.log(`Kubernetes status: ${degraded ? "DEGRADED" : "HEALTHY"}`);
for (const finding of findings) {
  console.log(`\n${finding.title}`);
  for (const line of finding.lines) console.log(`- ${line}`);
}
if (degraded) process.exit(1);

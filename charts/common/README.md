# 🧱 common (library chart)

Shared template partials for the cute.haus app charts. App charts depend on
this and include the partials they need from their own `templates/*.yaml`:

```yaml
# charts/<app>/templates/deployment.yaml
{ { - include "common.deployment" . } }
```

All partials read directly from the consumer chart's `.Values` and use
`.Chart.Name` for resource names. PVCs render as `<chart>-data`.

---

## Partials

| Define              | Renders                                 | Conditional on                |
| ------------------- | --------------------------------------- | ----------------------------- |
| `common.deployment` | `apps/v1` Deployment                    | always                        |
| `common.service`    | `v1` Service                            | always                        |
| `common.ingress`    | `networking.k8s.io/v1` Ingress          | `.Values.ingress.enabled`     |
| `common.pvc`        | PVC with `helm.sh/resource-policy:keep` | `.Values.persistence.enabled` |
| `common.secret`     | Opaque Secret (envFrom target)          | `.Values.envFromSecret` set   |

---

## Values reference

### Deployment

```yaml
replicaCount: 1 # default 1
strategy: Recreate # optional; "RollingUpdate" or "Recreate"
spread: false # if true AND replicas > 1, adds topologySpreadConstraints by hostname
dnsPolicy: Default # optional; passed through to pod spec
podSecurityContext: {} # optional; passed through (e.g. fsGroup: 1000)

image:
  repository: foo/bar
  tag: latest
  pullPolicy: Always # default IfNotPresent

resources: # optional; passed through
  requests: { cpu: 50m, memory: 64Mi }
  limits: { cpu: 1, memory: 256Mi }

ports: # raw k8s containerPort shape
  - { name: http, containerPort: 80 }

env: {} # plain key/value, rendered as name/value pairs
envFromSecret: "" # name of the Secret to envFrom (rendered separately by common.secret)

persistence:
  enabled: false # if true, mounts a PVC named <chart>-data
  storageClassName: longhorn
  size: 1Gi
  mountPath: /data

failover: # shorten the per-pod toleration for not-ready/unreachable taints
  fastTolerationSeconds: 60 # default toleration is 300 (5min); set this to evict sooner

probes: # any/all of startup, liveness, readiness
  startup:
    {
      httpGet: { path: /, port: http },
      periodSeconds: 10,
      failureThreshold: 30,
    }
  liveness: { httpGet: { path: /, port: http }, periodSeconds: 30 }
  readiness: { httpGet: { path: /, port: http }, periodSeconds: 10 }
```

### Service

```yaml
service:
  type: ClusterIP # default ClusterIP
  ports:
    - name: http
      port: 80
      targetPort: 80 # defaults to .port; can be int or named ("http" → ports[].name)
      nodePort: 8282 # optional; only used when type=NodePort
```

### Ingress

```yaml
ingress:
  enabled: true
  className: traefik
  routes:
    - host: example.com
      aliases: [www.example.com] # optional; additional hosts under same TLS
      tlsSecret: example-com-tls # name of an existing kubernetes.io/tls Secret
```

The ingress backend always points at the chart's own Service on
`service.ports[0].port`.

### Secret

```yaml
envFromSecret: foo-env # name of the Secret to render
secret: # filled by vals from values/<chart>.yaml
  KEY: value
```

Renders one `Opaque` Secret with the contents of `.Values.secret` as
`stringData`. The chart's `templates/secret.yaml` is just
`{{- include "common.secret" . }}`.

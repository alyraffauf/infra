# common (library chart)

Shared template partials for cute.haus app charts. App charts depend on
this and include the partials they need from their own `templates/*.yaml`:

```yaml
{ { - include "common.service" . } }
```

Deployments are hand-written per app — no shared template. All partials
read from the consumer chart's `.Values` and use `.Chart.Name` for names.

---

## Partials

| Define           | Renders                                 | Conditional on                |
| ---------------- | --------------------------------------- | ----------------------------- |
| `common.service` | `v1` Service                            | always                        |
| `common.ingress` | `networking.k8s.io/v1` Ingress          | `.Values.ingress.enabled`     |
| `common.pvc`     | PVC with `helm.sh/resource-policy:keep` | `.Values.persistence.enabled` |
| `common.secret`  | Opaque Secret (envFrom target)          | `.Values.envFromSecret` set   |

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

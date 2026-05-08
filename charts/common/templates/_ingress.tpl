{{- define "common.ingress" -}}
{{- if .Values.ingress.enabled -}}
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: {{ .Chart.Name }}
  labels:
    app: {{ .Chart.Name }}
spec:
  ingressClassName: {{ .Values.ingress.className }}
  tls:
    {{- range .Values.ingress.routes }}
    {{- $hosts := prepend (default (list) .aliases) .host }}
    - hosts:
        {{- range $hosts }}
        - {{ . }}
        {{- end }}
      secretName: {{ .tlsSecret }}
    {{- end }}
  rules:
    {{- $svcPort := (index $.Values.service.ports 0).port }}
    {{- range .Values.ingress.routes }}
    {{- $hosts := prepend (default (list) .aliases) .host }}
    {{- range $hosts }}
    - host: {{ . }}
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: {{ $.Chart.Name }}
                port:
                  number: {{ $svcPort }}
    {{- end }}
    {{- end }}
{{- end -}}
{{- end -}}

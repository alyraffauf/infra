{{- define "common.secret" -}}
{{- if .Values.envFromSecret -}}
apiVersion: v1
kind: Secret
metadata:
  name: {{ .Values.envFromSecret }}
  labels:
    app: {{ .Chart.Name }}
type: Opaque
stringData:
  {{- range $k, $v := .Values.secret }}
  {{ $k }}: {{ $v | quote }}
  {{- end }}
{{- end -}}
{{- end -}}

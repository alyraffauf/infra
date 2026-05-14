{{- define "common.secret" -}}
{{- if .Values.envFromSecret -}}
{{/* The chart manages the first entry in envFromSecret; later entries
     are written by ansible or other out-of-band processes. */}}
apiVersion: v1
kind: Secret
metadata:
  name: {{ index .Values.envFromSecret 0 }}
  labels:
    app: {{ .Chart.Name }}
type: Opaque
stringData:
  {{- range $k, $v := .Values.secret }}
  {{ $k }}: {{ $v | quote }}
  {{- end }}
{{- end -}}
{{- end -}}

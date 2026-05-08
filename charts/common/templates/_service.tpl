{{- define "common.service" -}}
apiVersion: v1
kind: Service
metadata:
  name: {{ .Chart.Name }}
  labels:
    app: {{ .Chart.Name }}
spec:
  type: {{ .Values.service.type | default "ClusterIP" }}
  selector:
    app: {{ .Chart.Name }}
  ports:
    {{- range .Values.service.ports }}
    - name: {{ .name | default "http" }}
      port: {{ .port }}
      targetPort: {{ .targetPort | default .port }}
      protocol: {{ .protocol | default "TCP" }}
      {{- if .nodePort }}
      nodePort: {{ .nodePort }}
      {{- end }}
    {{- end }}
{{- end -}}

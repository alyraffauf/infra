{{- define "common.pvc" -}}
{{- if and .Values.persistence .Values.persistence.enabled -}}
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: {{ .Chart.Name }}-data
  labels:
    app: {{ .Chart.Name }}
  annotations:
    helm.sh/resource-policy: keep
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: {{ .Values.persistence.storageClassName }}
  resources:
    requests:
      storage: {{ .Values.persistence.size }}
{{- end -}}
{{- end -}}

{{- define "common.deployment" -}}
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ .Chart.Name }}
  labels:
    app: {{ .Chart.Name }}
spec:
  replicas: {{ .Values.replicaCount | default 1 }}
  {{- with .Values.strategy }}
  strategy:
    type: {{ . }}
  {{- end }}
  selector:
    matchLabels:
      app: {{ .Chart.Name }}
  template:
    metadata:
      labels:
        app: {{ .Chart.Name }}
    spec:
      {{- with .Values.dnsPolicy }}
      dnsPolicy: {{ . }}
      {{- end }}
      {{- if hasKey .Values "enableServiceLinks" }}
      enableServiceLinks: {{ .Values.enableServiceLinks }}
      {{- end }}
      {{- with .Values.terminationGracePeriodSeconds }}
      terminationGracePeriodSeconds: {{ . }}
      {{- end }}
      {{- with .Values.podSecurityContext }}
      securityContext:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- with .Values.imagePullSecrets }}
      imagePullSecrets:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- if .Values.spread }}
      topologySpreadConstraints:
        - maxSkew: 1
          topologyKey: kubernetes.io/hostname
          whenUnsatisfiable: DoNotSchedule
          labelSelector:
            matchLabels:
              app: {{ .Chart.Name }}
      {{- end }}
      {{- if and .Values.failover .Values.failover.fastTolerationSeconds }}
      tolerations:
        - key: node.kubernetes.io/not-ready
          operator: Exists
          effect: NoExecute
          tolerationSeconds: {{ .Values.failover.fastTolerationSeconds }}
        - key: node.kubernetes.io/unreachable
          operator: Exists
          effect: NoExecute
          tolerationSeconds: {{ .Values.failover.fastTolerationSeconds }}
      {{- end }}
      containers:
        - name: {{ .Chart.Name }}
          image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
          imagePullPolicy: {{ .Values.image.pullPolicy | default "IfNotPresent" }}
          {{- with .Values.ports }}
          ports:
            {{- toYaml . | nindent 12 }}
          {{- end }}
          {{- with .Values.env }}
          env:
            {{- range $k, $v := . }}
            - name: {{ $k }}
              value: {{ $v | quote }}
            {{- end }}
          {{- end }}
          {{- with .Values.envFromSecret }}
          envFrom:
            {{- range . }}
            - secretRef:
                name: {{ . }}
            {{- end }}
          {{- end }}
          {{- with .Values.resources }}
          resources:
            {{- toYaml . | nindent 12 }}
          {{- end }}
          {{- $hasMounts := or (and .Values.persistence .Values.persistence.enabled) .Values.extraVolumeMounts .Values.rclone }}
          {{- if $hasMounts }}
          volumeMounts:
            {{- if and .Values.persistence .Values.persistence.enabled }}
            {{- if not (hasKey .Values.persistence "mountPath") }}
            - name: data
              mountPath: /data
            {{- else if .Values.persistence.mountPath }}
            - name: data
              mountPath: {{ .Values.persistence.mountPath }}
            {{- end }}
            {{- end }}
            {{- with .Values.extraVolumeMounts }}
            {{- toYaml . | nindent 12 }}
            {{- end }}
            {{- if .Values.rclone }}
            - name: rclone-media
              mountPath: {{ .Values.rclone.mountPath }}
              mountPropagation: HostToContainer
            {{- end }}
          {{- end }}
          {{- with .Values.probes }}
          {{- with .startup }}
          startupProbe:
            {{- toYaml . | nindent 12 }}
          {{- end }}
          {{- with .liveness }}
          livenessProbe:
            {{- toYaml . | nindent 12 }}
          {{- end }}
          {{- with .readiness }}
          readinessProbe:
            {{- toYaml . | nindent 12 }}
          {{- end }}
          {{- end }}
        {{- with .Values.extraContainers }}
        {{- toYaml . | nindent 8 }}
        {{- end }}
        {{- if .Values.rclone }}
        - name: rclone
          image: "{{ .Values.rclone.image.repository }}:{{ .Values.rclone.image.tag }}"
          imagePullPolicy: {{ .Values.rclone.image.pullPolicy | default "IfNotPresent" }}
          args:
            - mount
            - {{ .Values.rclone.remote | quote }}
            - {{ .Values.rclone.mountPath | quote }}
            - --allow-non-empty
            {{- if .Values.rclone.readOnly }}
            - --read-only
            {{- end }}
            {{- if .Values.rclone.allowOther }}
            - --allow-other
            {{- end }}
            - --vfs-cache-mode=full
            - --vfs-cache-max-age={{ .Values.rclone.vfsCacheMaxAge }}
            - --vfs-cache-max-size={{ .Values.rclone.vfsCacheMaxSize }}
            - --uid={{ .Values.rclone.uid | default 1000 }}
            - --gid={{ .Values.rclone.gid | default 1000 }}
            - --umask=022
            - --log-level=INFO
          securityContext:
            privileged: true
          {{- $rcloneSecrets := .Values.rclone.envFromSecret | default .Values.envFromSecret }}
          {{- with $rcloneSecrets }}
          envFrom:
            {{- range . }}
            - secretRef:
                name: {{ . }}
            {{- end }}
          {{- end }}
          volumeMounts:
            - name: rclone-media
              mountPath: {{ .Values.rclone.mountPath }}
              mountPropagation: Bidirectional
        {{- end }}
      {{- $hasVolumes := or (and .Values.persistence .Values.persistence.enabled) .Values.extraVolumes .Values.rclone }}
      {{- if $hasVolumes }}
      volumes:
        {{- if and .Values.persistence .Values.persistence.enabled }}
        - name: data
          persistentVolumeClaim:
            claimName: {{ .Chart.Name }}-data
        {{- end }}
        {{- with .Values.extraVolumes }}
        {{- toYaml . | nindent 8 }}
        {{- end }}
        {{- if .Values.rclone }}
        - name: rclone-media
          emptyDir: {}
        {{- end }}
      {{- end }}
{{- end -}}

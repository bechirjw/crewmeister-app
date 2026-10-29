{{- define "crewmeister.name" -}}crewmeister{{- end -}}
{{- define "crewmeister.fullname" -}}
{{- default .Release.Name .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- define "crewmeister.labels" -}}
app.kubernetes.io/name: crewmeister
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

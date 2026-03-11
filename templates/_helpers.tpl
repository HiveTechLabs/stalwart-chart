{{/*
Expand the name of the chart.
*/}}
{{- define "stalwart.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "stalwart.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "stalwart.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "stalwart.labels" -}}
helm.sh/chart: {{ include "stalwart.chart" . }}
{{ include "stalwart.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "stalwart.selectorLabels" -}}
app.kubernetes.io/name: {{ include "stalwart.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "stalwart.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "stalwart.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Environment variables for external storage backends.
*/}}
{{- define "stalwart.storageEnv" -}}
- name: STALWART_POSTGRES_USERNAME
  valueFrom:
    secretKeyRef:
      name: {{ .Values.postgresql.secretName }}
      key: {{ .Values.postgresql.usernameKey }}
- name: STALWART_POSTGRES_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ .Values.postgresql.secretName }}
      key: {{ .Values.postgresql.passwordKey }}
{{- if .Values.valkey.usernameKey }}
- name: STALWART_VALKEY_USERNAME
  valueFrom:
    secretKeyRef:
      name: {{ .Values.valkey.secretName }}
      key: {{ .Values.valkey.usernameKey }}
{{- end }}
- name: STALWART_VALKEY_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ .Values.valkey.secretName }}
      key: {{ .Values.valkey.passwordKey }}
- name: STALWART_S3_ACCESS_KEY
  valueFrom:
    secretKeyRef:
      name: {{ .Values.s3.secretName }}
      key: {{ .Values.s3.accessKeyKey }}
- name: STALWART_S3_BUCKET
  valueFrom:
    secretKeyRef:
      name: {{ .Values.s3.secretName }}
      key: {{ .Values.s3.bucketKey }}
- name: STALWART_S3_ENDPOINT
  valueFrom:
    secretKeyRef:
      name: {{ .Values.s3.secretName }}
      key: {{ .Values.s3.endpointKey }}
- name: STALWART_S3_SECRET_KEY
  valueFrom:
    secretKeyRef:
      name: {{ .Values.s3.secretName }}
      key: {{ .Values.s3.secretKeyKey }}
{{- end }}

# gcp-gs-downloader

A super simple, lightweight container intended to be used as an init-container in kubernetes to download assets from Google Cloud Storage.

### Usage

```
docker run -v $PATH/to/credential.json:/credential.json -e SRC="gs://some-bucket/*.fileglob" DEST="/data/" vaporio/gcp-gs-downloader:latest
```

### Consume as a helm chart init container

Using the CookieCutter template for [vapor-helm-starter](https://github.com/vapor-ware/vapor-helm-starter), this can be declared inline in the deployment spec. We can also ease the integration by leveraging the values.yaml segments where appropriate to configure the init container:

Consider the following init container snippet, presuming we have a secret for the GCP Service Account JSON Credential mounted at `/secrets/google-sync-credential`, and we want to download to the `/data` path:

```yaml
      initContainers:
      - name: download
        image: vaporio/gcp-gs-downloader:latest
        env:
        {{- with .Values.env }}
        {{- toYaml . | trim | nindent 8 }}
        {{- end }}
        - name: GOOGLE_APPLICATION_CREDENTIALS
          value: /secrets/google-sync-credential
        volumeMounts:
        - name: workspace
          mountPath: /data
        - name: podinfo
          mountPath: /etc/podinfo
        {{- if .Values.secrets.volumes }}
        {{- range .Values.secrets.volumes }}
        - name: {{ .name }}
          mountPath: /secrets
        {{- end }}
        {{- end }}
```

And the following `values.yaml` snippets:

```yaml
pod:
  annotations:
    # Google storage bucket configuration annotations. Used in automation between map-feature-api and tileserver-gl init container to provision mbtiles for serving from Google Cloud Storage.
    gs/src: "gs://vio-mbtiles/fallback/*.mbtiles"
secrets:
  volumes:
    - name: google-sync-credential
      value: |
        {
          "type": "service_account",
          ... More JSON blob here ...
        }
      type: Opaque
      labels: {}
      annotations: {}
```

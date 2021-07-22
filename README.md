# gcp-gs-downloader

A super simple, lightweight container intended to be used as an init-container in kubernetes to download assets from Google Cloud Storage.

### Usage

```shell
docker run -v $PATH/to/credential.json:/credential.json -e SRC="gs://some-bucket/*.fileglob" vaporio/gcp-gs-downloader:latest
```

### Consume as a helm chart init container

This container being used as an initContainer image lends itself to being re-configured dynamically. This is why it expects volume-mounted `podinfo` directory with `annotations` so we can post/parse appropriately.

Using the CookieCutter template for [vapor-helm-starter](https://github.com/vapor-ware/vapor-helm-starter), this can be declared inline in the deployment spec. We can also ease the integration by leveraging the values.yaml segments where appropriate to configure the init container:

Consider the following init container snippet, presuming we have a secret for the GCP Service Account JSON Credential mounted at `/secrets/google-sync-credential`, and we want to download to the `/data` path:

```yaml
      volumes:
        - name: workspace
          emptyDir: {}
        - name: podinfo
          downwardAPI:
            items:
              - path: "annotations"
                fieldRef:
                  fieldPath: metadata.annotations
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

Once deployed, you can test patching the template annotations:

```shell
kubectl patch deployment my-deployment -p \ "{\"spec\":{\"template\":{\"metadata\":{\"annotations\": {\"gs/src\": \"gs://vio-mbtiles/20210211T220432427065/fiber.mbtiles\"}}}}}"

```

## FAQ

### How Do I manage the ServiceAccount Secret?

We recommend using [`sctl`](https://github.com/vapor-ware/sctl) to manage secrets. You can safely version cyphertext of the contents of the service-account JSON file, and populate in the chart at `helm install` time by exposing as an ENV var.  We consume these typically with `helmfile` in `vapor-ware/cloud-ops` or `vapor-ware/edge-ops` repositories respectively. Note the value is multi-line and must be handled appropriately.

eg:

```yaml
release:
  name: my-release
  values:
  - secrets:
      - name: GOOGLE_APPLICATION_CREDENTIAL
        value: | {{ requiredENV "SYNC_CREDENTIAL" | nindent 8 }}
```

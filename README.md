# docker-gs-downloader

A super simple, lightweight container intended to be used as an init-container in kubernetes to download assets from Google Cloud Storage.

### Usage

```
docker run -v $PATH/to/credential.json:/credential.json -e SRC="gs://some-bucket/*.fileglob" DEST="/data/" vaporio/gcp-gs-downloader:latest
```

### Consume as a helm chart init container

TODO

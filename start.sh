#!/bin/bash

# A simple wrapper to parse out details for a file sync from GCS
# configurable via ENV SRC or Annotations `gs/src`

ANNOTATION_FILE="/etc/podinfo/annotations"
ANNOTATION_SOURCE="gs/src"
# Container assumed default DEST
DEFAULT_DEST="/data/"
PARSED_SOURCE=""


# TODO: Refactor to describe setting annotations, or ENV
printUsage () {
	echo "Usage:  start.sh"
	echo "This script expects ENV vars SRC to be provided"
	echo "Alternatively: if in kubernetes, use the downward API to provide ANNOTATIONS"
	echo "at /etc/podinfo/annotations. It will parse for gs/src"
}

# The integration point from Kubernetes expects a path in
# /etc/podinfo/annotations to contain the pod annotations
# set on the deployment. We'll process this file for the
# annotations `gs/src` to configure the jobs source.
#
# sample podinfo:
# checksum/config="01ba4719c80b6fe911b091a7c05124b64eeece964e09c058ef8f9805daca546b"
# gs/fallback="gs://vio-mbtiles/fallback/*.mbtiles"
# gs/src=""
# kubernetes.io/config.seen="2021-02-15T08:55:41.182064904-06:00"
# kubernetes.io/config.source="api"

parseAnnotations() {
	# if the file does not exist, presume local runtime or non-k8s tooling
	if [ ! -f "${ANNOTATION_FILE}" ];
	then
		gcloud auth activate-service-account --key-file=${GOOGLE_APPLICATION_CREDENTIALS}
		files=$(gsutil ls -r "gs://${GCS_BUCKET}/*/*.mbtiles")
		myarray=($files)
		IFS=$'\n' sorted=($(sort -r <<<"${myarray[*]}"))
		unset IFS

		PARSED_SOURCE="${sorted[0]}"

		echo "Missing pod annotations, skipping Kubernetes integration. Expecting configuration to be provided via ENV vars SRC and DEST."
		echo "Falling back to most recent mbtiles file in bucket: ${PARSED_SOURCE}"
		return
	fi

	# parse source
	FOUND_SOURCE=$(cat ${ANNOTATION_FILE} | grep ${ANNOTATION_SOURCE})

	# Export the PARSED_SOURCE var
	PARSED_SOURCE=$(echo ${FOUND_SOURCE} | cut -f 2 -d = | tr -d '"')
	echo "Found source: ${PARSED_SOURCE}"
}


parseAnnotations

if [ ! -z "${PARSED_SOURCE}" ]; then
	SRC=$PARSED_SOURCE
fi

if [ -z "${SRC}" ]; then
	echo "Missing SOURCE argument, source path"
	printUsage
	exit 1
fi



# Set x-mode for clarity of commands the container is executing
set -eux
# Authenticate to the GCP API, setting account credentials as default identity
gcloud auth activate-service-account --key-file=${GOOGLE_APPLICATION_CREDENTIALS}
gsutil cp -r ${SRC} ${DEFAULT_DEST}
ls -al ${DEFAULT_DEST}

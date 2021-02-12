#!/bin/sh

set -e

printUsage () {
	echo "Usage:  start.sh gcs://some-bucket/path/*.files /data/"
}

if [ -z "${SRC}" ]; then
	echo "Missing first argument, source path"
	printUsage
	exit 1
fi


if [ -z "${DEST}" ]; then
	echo "Missing second argument, dest path"
    printUsage
	exit 1
fi

set -x

# Authenticate to the GCP API, setting account credentials as default identity
gcloud auth activate-service-account --key-file=${GOOGLE_APPLICATION_CREDENTIALS}
gsutil cp -r ${SRC} ${DEST}
ls -al /data

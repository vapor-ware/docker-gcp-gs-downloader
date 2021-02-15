FROM gcr.io/google.com/cloudsdktool/cloud-sdk:alpine

ENV SRC=""

ADD start.sh /start.sh
RUN mkdir -p /data
CMD ["/start.sh"]

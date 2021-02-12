FROM gcr.io/google.com/cloudsdktool/cloud-sdk:alpine

ENV SRC=""
ENV DEST=""

ADD start.sh /start.sh
RUN mkdir -p /data
CMD ["/start.sh"]

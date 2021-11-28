ARG BASEIMAGE=alpine:latest
FROM ${BASEIMAGE}

ARG BUILD_DATE
ARG VCS_REF
ARG VERSION
LABEL mantainer="Eloy Lopez <elswork@gmail.com>" \
    org.opencontainers.image.title="Samba" \
    org.opencontainers.image.description="Multiarch Samba Docker container" \
    org.opencontainers.image.vendor=Deft.Work \
    org.opencontainers.image.url=https://deft.work/Samba \
    org.opencontainers.image.source=https://github.com/DeftWork/samba \
    org.opencontainers.image.version=$VERSION \ 
    org.opencontainers.image.created=$BUILD_DATE \
    org.opencontainers.image.revision=$VCS_REF \
    org.opencontainers.image.licenses=MIT

RUN apk update && apk upgrade && apk add --no-cache bash samba-common-tools samba tzdata && rm -rf /var/cache/apk/*

COPY entrypoint.sh /entrypoint.sh
RUN chmod u+x /entrypoint.sh

EXPOSE 137/udp 138/udp 139 445

HEALTHCHECK --interval=60s --timeout=15s CMD smbclient -L \\localhost -U % -m SMB3

ENTRYPOINT ["/entrypoint.sh"]
CMD ["-h"]
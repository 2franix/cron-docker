FROM alpine:3.19.0

RUN apk update
RUN apk add x2goserver shadow

COPY --chmod=500 ./entrypoint.sh /entrypoint.sh

ENTRYPOINT [ "/bin/sh", "/entrypoint.sh" ]

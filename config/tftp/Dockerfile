FROM alpine:3.22

RUN apk add --no-cache dnsmasq alpine-ipxe

ENTRYPOINT ["dnsmasq"]
CMD ["--port=0", "--enable-tftp", "--tftp-root=/usr/share/alpine-ipxe", \
     "--interface=eth2", "--bind-interfaces", "--no-daemon", "--log-facility=-"]

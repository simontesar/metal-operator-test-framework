FROM alpine:3.22

# Guests are OVMF x86_64
RUN apk add --no-cache dnsmasq curl \
	&& mkdir -p /usr/share/ipxe \
	&& curl -fsSL -o /usr/share/ipxe/ipxe.efi \
		https://boot.ipxe.org/x86_64-efi/ipxe.efi \
	&& curl -fsSL -o /usr/share/ipxe/snponly.efi \
		https://boot.ipxe.org/x86_64-efi/snponly.efi

ENTRYPOINT ["dnsmasq"]
CMD ["--port=0", "--enable-tftp", "--tftp-root=/usr/share/ipxe", \
     "--interface=eth2", "--bind-interfaces", "--no-daemon", "--log-facility=-"]

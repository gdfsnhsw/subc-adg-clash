FROM --platform=$TARGETPLATFORM golang:alpine AS builder
ARG TARGETPLATFORM
ARG BUILDPLATFORM

# RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g' /etc/apk/repositories

RUN apk add --no-cache curl jq unzip

WORKDIR /go
RUN set -eux; \
    \
    if [ "${TARGETPLATFORM}" = "linux/amd64" ]; then architecture="linux-amd64" ; fi; \
    if [ "${TARGETPLATFORM}" = "linux/arm64" ]; then architecture="linux-armv8" ; fi; \
    if [ "${TARGETPLATFORM}" = "linux/arm/v7" ] ; then architecture="linux-armv7" ; fi; \
    clash_download_url=$(curl -L https://api.github.com/repos/Dreamacro/clash/releases/tags/premium | jq -r --arg architecture "$architecture" '.assets[] | select (.name | contains($architecture)) | .browser_download_url' -); \
    curl -L $clash_download_url | gunzip - > clash;

RUN set -eux; \
    \
    curl -L -O https://github.com/Dreamacro/maxmind-geoip/releases/latest/download/Country.mmdb;
    
RUN set -eux; \
    \
    curl -L -O https://github.com/Dreamacro/clash-dashboard/archive/refs/heads/gh-pages.zip; \
    unzip gh-pages.zip; 
    
FROM --platform=$TARGETPLATFORM alpine AS runtime
LABEL org.opencontainers.image.source https://gdfsnhsw@github.com/gdfsnhsw/subc-adg-clash.git
ARG TARGETPLATFORM
ARG BUILDPLATFORM

# RUN echo "https://mirror.tuna.tsinghua.edu.cn/alpine/v3.11/main/" > /etc/apk/repositories

COPY --from=builder /go/clash /usr/local/bin/
COPY --from=builder /go/Country.mmdb /root/.config/clash/
COPY --from=builder /go/clash-dashboard-gh-pages/CNAME /root/.config/clash/dashboard/
COPY --from=builder /go/clash-dashboard-gh-pages/index.html /root/.config/clash/dashboard/
COPY --from=builder /go/clash-dashboard-gh-pages/assets/* /root/.config/clash/dashboard/assets/
COPY config.yaml.example /root/.config/clash/config.yaml
COPY entrypoint.sh /usr/local/bin/
COPY scripts/* /usr/lib/clash/

# RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g' /etc/apk/repositories

RUN set -eux; \
    buildDeps=" \
    	jq \
        git \
        autoconf \
        automake \
        libtool \
        help2man \
        build-base \
        bash \
	nftables \
        iproute2 \
        ip6tables \
        iptables \
    "; \
    runDeps=" \
        bash \
        iproute2 \
	nftables \
        ca-certificates \
        tini \
	libcap \
        curl \
        bind-tools \
        bash-doc \
        bash-completion \
    "; \
    \
    apk add --no-cache --virtual .build-deps \
        $buildDeps \
        $runDeps \
    ; \
    \
    apk add --no-network --virtual .run-deps \
        $runDeps \
    ; \
    apk del .build-deps; \
    \
    # clash
    \
    chmod a+x /usr/local/bin/* /usr/lib/clash/*; \
    # dumped by `pscap` of package `libcap-ng-utils`
    setcap cap_chown,cap_dac_override,cap_fowner,cap_fsetid,cap_kill,cap_setgid,cap_setuid,cap_setpcap,cap_net_bind_service,cap_net_raw,cap_sys_chroot,cap_mknod,cap_audit_write,cap_setfcap,cap_net_admin=+ep /usr/local/bin/clash


WORKDIR /clash_config

ENTRYPOINT ["entrypoint.sh"]
CMD ["su", "-s", "/bin/bash", "-c", "/usr/local/bin/clash -d /clash_config", "nobody"]

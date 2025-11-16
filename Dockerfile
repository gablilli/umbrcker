# syntax=docker/dockerfile:1

ARG YQ_VERSION=4.24.5
ARG NODE_VERSION=22.13.0
ARG DEBIAN_VERSION=bookworm
ARG UMBREL_VERSION=1.5.0

#########################################################################
# base stage
#########################################################################
FROM --platform=$BUILDPLATFORM debian:${DEBIAN_VERSION}-slim AS base

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl tar ca-certificates git \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /tmp

RUN curl -fsSL https://github.com/getumbrel/umbrel/archive/refs/tags/${UMBREL_VERSION}.tar.gz -o umbrel.tar.gz \
    && mkdir /umbreld \
    && tar -xzf umbrel.tar.gz --strip-components=1 -C /umbreld \
    && rm umbrel.tar.gz

COPY source /packages/umbreld/source

#########################################################################
# ui build stage
#########################################################################
FROM --platform=$BUILDPLATFORM node:${NODE_VERSION}-${DEBIAN_VERSION} AS ui-build

WORKDIR /app

COPY --from=base /umbreld/packages/ui/ ./

RUN npm install -g pnpm@8
RUN rm -rf node_modules || true
RUN pnpm install

RUN pnpm run build

#########################################################################
# backend build stage
#########################################################################
FROM node:${NODE_VERSION}-${DEBIAN_VERSION} AS be-build

WORKDIR /opt/umbreld

COPY --from=base /umbreld/packages/umbreld/ /opt/umbreld/
COPY --from=ui-build /app/dist /opt/umbreld/ui

RUN chmod +x /opt/umbreld/source/modules/apps/legacy-compat/app-script

RUN rm -rf node_modules || true
RUN npm clean-install --omit dev && npm link

#########################################################################
# umbrelos build stage (finale)
#########################################################################
FROM debian:${DEBIAN_VERSION}-slim AS umbrelos

ENV NODE_ENV=production

ARG TARGETARCH
ARG YQ_VERSION
ARG NODE_VERSION
ARG UMBREL_VERSION

RUN set -eux \
  && apt-get update -y \
  && apt-get install -y --no-install-recommends \
    sudo nano vim less man iproute2 iputils-ping curl wget ca-certificates \
    python3 fswatch jq rsync git gettext-base gnupg libnss-mdns p7zip-full \
    imagemagick ffmpeg tini \
  && curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker.gpg \
  && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker.gpg] https://download.docker.com/linux/debian bookworm stable" | tee /etc/apt/sources.list.d/docker.list \
  && apt-get update -y \
  && apt-get install -y --no-install-recommends docker-ce-cli docker-compose-plugin \
  && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
  && NODE_ARCH=$([ "${TARGETARCH}" = "arm64" ] && echo "arm64" || echo "x64") \
  && curl -fsSL "https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-${NODE_ARCH}.tar.gz" -o node.tar.gz \
  && tar -xz -f node.tar.gz -C /usr/local --strip-components=1 \
  && rm -rf node.tar.gz \
  && curl -fsLo /usr/local/bin/yq "https://github.com/mikefarah/yq/releases/download/v${YQ_VERSION}/yq_linux_${TARGETARCH}" \
  && chmod +x /usr/local/bin/yq \
  && echo "${UMBREL_VERSION}" > /run/version \
  && addgroup --gid 1000 umbrel \
  && adduser --uid 1000 --gid 1000 --gecos "" --disabled-password umbrel \
  && echo "umbrel:umbrel" | chpasswd \
  && usermod -aG sudo umbrel

COPY --chmod=755 ./entry.sh /run/
COPY --from=be-build --chmod=755 /opt/umbreld /opt/umbreld

VOLUME /data
EXPOSE 80 443

ENTRYPOINT ["/usr/bin/tini", "-s", "/run/entry.sh"]

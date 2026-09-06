FROM        --platform=$TARGETOS/$TARGETARCH node:19-bullseye-slim
LABEL author="siputzx" \
      maintainer="kavionn" \
      org.opencontainers.image.source="https://github.com/kavionn/docker-panel-peterodactyl"

ARG YT_DLP_VERSION=2026.08.19
ARG YT_DLP_SHA256=1fa6733c37ea6fb51c99ad8fe785e7b7e5f3246c9b980230329d4fb72ed8d4d6

# Node 19 only has an official Bullseye image. Bullseye reached EOL on
# 2026-08-31, so use the final Debian snapshots instead of moving mirrors.
RUN printf '%s\n' \
        'deb [check-valid-until=no] https://snapshot.debian.org/archive/debian/20260831T000000Z bullseye main' \
        'deb [check-valid-until=no] https://snapshot.debian.org/archive/debian/20260831T000000Z bullseye-updates main' \
        'deb [check-valid-until=no] https://snapshot.debian.org/archive/debian-security/20260831T000000Z bullseye-security main' \
        > /etc/apt/sources.list

RUN useradd -m -d /home/container -s /bin/bash container
STOPSIGNAL SIGINT

RUN apt update \
    && apt -y install \
        ffmpeg \
        iproute2 \
        git \
        sqlite3 \
        libsqlite3-dev \
        python3 \
        python3-dev \
        python3-pip \
        python3-venv \
        ca-certificates \
        dnsutils \
        tzdata \
        zip \
        tar \
        curl \
        build-essential \
        libtool \
        iputils-ping \
        libnss3 \
        tini \
        gnupg \
        wget \
        imagemagick \
        libcairo2-dev \
        libpango1.0-dev \
        libjpeg-dev \
        libgif-dev \
        librsvg2-dev \
        libx11-6 \
        libx11-xcb1 \
        libxcb1 \
        libxcomposite1 \
        libxcursor1 \
        libxdamage1 \
        libxext6 \
        libxfixes3 \
        libxi6 \
        libxrandr2 \
        libxrender1 \
        libxss1 \
        libxtst6 \
        fonts-liberation \
        libappindicator3-1 \
        libasound2 \
        libatk-bridge2.0-0 \
        libatk1.0-0 \
        libcups2 \
        libdbus-1-3 \
        libdrm2 \
        libgbm1 \
        libgtk-3-0 \
        libnspr4 \
        libnss3 \
        libxshmfence1 \
    && rm -rf /var/lib/apt/lists/*
RUN apt-get update  \
    && for pkg in chromium chromium-browser; do  \
         if apt-cache show "$pkg" >/dev/null 2>&1; then  \
           apt-get install -y --no-install-recommends "$pkg" && break;  \
         fi;  \
       done  \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p --mode=0755 /usr/share/keyrings \
    && curl -fsSL https://pkg.cloudflare.com/cloudflare-public-v2.gpg -o /usr/share/keyrings/cloudflare-public-v2.gpg \
    && echo 'deb [signed-by=/usr/share/keyrings/cloudflare-public-v2.gpg] https://pkg.cloudflare.com/cloudflared any main' > /etc/apt/sources.list.d/cloudflared.list \
    && apt update \
    && apt -y install cloudflared \
    && apt clean \
    && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL \
        "https://github.com/yt-dlp/yt-dlp/releases/download/${YT_DLP_VERSION}/yt-dlp" \
        -o /usr/local/bin/yt-dlp \
    && echo "${YT_DLP_SHA256}  /usr/local/bin/yt-dlp" | sha256sum --check --strict \
    && chmod 0755 /usr/local/bin/yt-dlp \
    && printf '%s\n' '--js-runtimes node' > /etc/yt-dlp.conf \
    && test "$(yt-dlp --ignore-config --version)" = "${YT_DLP_VERSION}"

ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true \
    PUPPETEER_SKIP_DOWNLOAD=true \
    PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium \
    PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1 \
    PLAYWRIGHT_BROWSERS_PATH=/ms-playwright \
    COREPACK_ENABLE_DOWNLOAD_PROMPT=0 \
    COREPACK_HOME=/usr/local/lib/corepack

RUN npm install -g corepack
RUN corepack enable
RUN corepack prepare pnpm@latest --activate
RUN corepack exec pnpm -- config set --global dangerouslyAllowAllBuilds true || true

COPY --chmod=0755 nodejs/ptero-startup.sh /usr/local/bin/ptero-startup

RUN mkdir -p /ms-playwright && chown -R container:container /ms-playwright

USER container
ENV USER=container HOME=/home/container
WORKDIR /home/container

COPY --chown=container:container ../entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/usr/bin/tini", "-g", "--"]
CMD ["/entrypoint.sh"]

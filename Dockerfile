FROM ruby:4.0.5 AS ci_image

# dd1e5f94214632a09ce07426c2392ab8803ae8b307c0ba5436239e9b67d01c52  fly-7.12.1-linux-amd64.tgz
# b32f64e429e477fcfdcceb7c70a3378fee592377453106d944327cf87d78045e  fly-7.14.3-linux-amd64.tgz
# 587312235035326db285e54d7293080541168f42f95be45d199884e36d41c3e3  fly-8.2.1-linux-amd64.tgz
# https://github.com/concourse/concourse/releases/
# renovate: datasource=github-releases depName=concourse/concourse
ARG CONCOURSE_VERSION=8.2.3
ARG CONCOURSE_SHA256=f42fa93a390e16d8e14149d4559d0f46dda82d16bc01a60418c70808a7b1e2f6

# https://github.com/cloudfoundry/bosh-cli/releases
# renovate: datasource=github-releases depName=cloudfoundry/bosh-cli
ARG BOSH_CLI_VERSION=7.10.5
ARG BOSH_CLI_SHA256=e9847375ba5397589e7b070305defc70321ad0e62d18b67a70a330efcab6e526

# https://github.com/cli/cli/releases
# renovate: datasource=github-releases depName=cli/cli
ARG GH_CLI_VERSION=2.93.0

RUN apt-get update \
    && apt-get -y install --no-install-recommends tree vim netcat-traditional dnsutils jq

# install cf-ops-automation Gemfile
RUN gem update --system
RUN gem install bundler
RUN echo "Curl version: $(curl --version)"
COPY Gemfile /usr/local/Gemfile
COPY Gemfile.lock /usr/local/Gemfile.lock
WORKDIR "/usr/local"
RUN bundle install --retry 5

WORKDIR "/tmp"
# install fly-cli
ARG FLY_DOWNLOAD_URL="https://github.com/concourse/concourse/releases/download/v${CONCOURSE_VERSION}/fly-${CONCOURSE_VERSION}-linux-amd64.tgz"
RUN echo "Prepare FLY downloading at $FLY_DOWNLOAD_URL"
RUN curl --retry 30 -sSL "$FLY_DOWNLOAD_URL" -o /tmp/fly.tgz \
    && echo "Computed sha256sum: $(sha256sum /tmp/fly.tgz)" \
    && [ ${CONCOURSE_SHA256} = $(sha256sum /tmp/fly.tgz | cut -d' ' -f1) ] \
    && tar xzvf /tmp/fly.tgz \
    && mv /tmp/fly /usr/local/bin/fly \
    && chmod +x /usr/local/bin/fly \
    && rm -rf /tmp/fly*

ARG QLTY_INSTALL_URL="https://qlty-releases.s3.amazonaws.com/qlty"
ARG QLTY_TARGET="x86_64-unknown-linux-gnu"
RUN curl --retry 30 -sSL "$QLTY_INSTALL_URL/latest/qlty-$QLTY_TARGET.tar.xz" -o /tmp/qlty.tar.xz \
    && tar xJvf qlty.tar.xz \
    && du -a /tmp \
    && mv /tmp/qlty-$QLTY_TARGET/qlty /usr/local/bin/qlty \
    && chmod a+x /usr/local/bin/qlty \
    && rm -rf /tmp/qlty*

RUN curl --retry 30 -sSL "https://raw.githubusercontent.com/ekalinin/github-markdown-toc/master/gh-md-toc" -o /usr/local/bin/gh-md-toc \
    && chmod a+x /usr/local/bin/gh-md-toc

# Download BOSH v2 CLI
RUN curl --retry 30 -sSLo /usr/local/bin/bosh https://github.com/cloudfoundry/bosh-cli/releases/download/v${BOSH_CLI_VERSION}/bosh-cli-${BOSH_CLI_VERSION}-linux-amd64 \
    && echo "Computed sha256sum: $(sha256sum /usr/local/bin/bosh)" \
    && echo "${BOSH_CLI_SHA256} */usr/local/bin/bosh" | shasum -a 256 -c - \
    && chmod +x /usr/local/bin/bosh

ARG GH_BASE_FILENAME="gh_${GH_CLI_VERSION}_linux_amd64"
RUN curl --retry 30 -sSL "https://github.com/cli/cli/releases/download/v${GH_CLI_VERSION}/${GH_BASE_FILENAME}.tar.gz" -o /tmp/gh.tgz \
    && tar xzvf /tmp/gh.tgz ${GH_BASE_FILENAME}/bin/gh \
    && mv /tmp/${GH_BASE_FILENAME}/bin/gh /usr/local/bin/gh \
    && chmod +x /usr/local/bin/gh \
    && rm -rf /tmp/gh*

WORKDIR "/cf-ops-automation"
# Include repository content in the image; exclusions are handled by .dockerignore.
COPY . /cf-ops-automation

# remove old version of bundler to avoid confusion between bundler and bundle cmd
#   bundler => old binary
#   bundle => latest binary
RUN rm -f /usr/local/bundle/bin/bundler


FROM ci_image AS test_ci_image
RUN ruby --version && bosh --version && fly --version && qlty --version && gh-md-toc --version && gh version && echo "=== CLI tests successful ==="
RUN ls /cf-ops-automation && du -sh /cf-ops-automation && echo "=== CLI tests successful ==="


FROM ci_image

FROM ruby:3.4.8 AS ci_image

# 6cf7acfcde78a980339cba1534c01be28d360306e5c76c60c5546e3847434eb7  fly-7.9.1-linux-amd64.tgz
# 1701337abe34796eb59c01a9c5505d956ecc08a094fcd1232efbc781e9ababf8  fly-7.10.0-linux-amd64.tgz
# dd1e5f94214632a09ce07426c2392ab8803ae8b307c0ba5436239e9b67d01c52  fly-7.12.1-linux-amd64.tgz
# https://github.com/concourse/concourse/releases/
# renovate: datasource=github-releases depName=concourse/concourse
ARG CONCOURSE_VERSION=7.14.3
ARG CONCOURSE_SHA256=b32f64e429e477fcfdcceb7c70a3378fee592377453106d944327cf87d78045e

# https://github.com/cloudfoundry/bosh-cli/releases
# renovate: datasource=github-releases depName=cloudfoundry/bosh-cli
ARG BOSH_CLI_VERSION=7.9.16
ARG BOSH_CLI_SHA256=4b605e8d6325b417aa8dcfb14af0ec72036f9f361d0cd0cc0c4fab81af0a3afa

# https://github.com/cli/cli/releases
# renovate: datasource=github-releases depName=cli/cli
ARG GH_CLI_VERSION=2.83.0

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

# remove old version of bundler to avoid confusion between bundler and bundle cmd
#   bundler => old binary
#   bundle => latest binary
RUN rm -f /usr/local/bundle/bin/bundler


FROM ci_image AS test_ci_image
RUN ruby --version && bosh --version && fly --version && qlty --version && gh-md-toc --version && gh version


FROM ci_image

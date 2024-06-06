FROM ruby:3.1.2

# 92c56cb432c5d86d8687d765bd6d0847dc80edfbab28a878a9c11eec9289b02d  fly-7.8.2-linux-amd64.tgz
# 6cf7acfcde78a980339cba1534c01be28d360306e5c76c60c5546e3847434eb7  fly-7.9.1-linux-amd64.tgz
# 1701337abe34796eb59c01a9c5505d956ecc08a094fcd1232efbc781e9ababf8  fly-7.10.0-linux-amd64.tgz
# https://github.com/concourse/concourse/releases/
# renovate: datasource=github-releases depName=concourse/concourse
ARG CONCOURSE_VERSION=7.11.2
ARG CONCOURSE_SHA256=1701337abe34796eb59c01a9c5505d956ecc08a094fcd1232efbc781e9ababf8

# https://github.com/cloudfoundry/bosh-cli/releases
# renovate: datasource=github-releases depName=cloudfoundry/bosh-cli
ARG BOSH_CLI_VERSION=7.6.1
ARG BOSH_CLI_SHA256=f090d6962a56d946f9592105f6a97956f77d4b6f527e184105355d3f46f354ad

RUN apt-get update && \
 apt-get -y install tree vim netcat dnsutils jq

# install cf-ops-automation Gemfile
RUN gem update --system
RUN gem install bundler
RUN echo "Curl version: $(curl --version)"
COPY Gemfile /usr/local/Gemfile
COPY Gemfile.lock /usr/local/Gemfile.lock
RUN cd /usr/local && bundle install --retry 5

# install fly-cli
ARG FLY_DOWNLOAD_URL="https://github.com/concourse/concourse/releases/download/v${CONCOURSE_VERSION}/fly-${CONCOURSE_VERSION}-linux-amd64.tgz"
RUN echo "Prepare FLY downloading at $FLY_DOWNLOAD_URL"
RUN curl --retry 30 -SL "$FLY_DOWNLOAD_URL" -o /tmp/fly.tgz \
  && echo "Computed sha256sum: $(sha256sum /tmp/fly.tgz)" \
  && [ ${CONCOURSE_SHA256} = $(sha256sum /tmp/fly.tgz | cut -d' ' -f1) ] \
  && cd /tmp \
  && tar xzvf /tmp/fly.tgz \
  && mv /tmp/fly /usr/local/bin/fly \
  && chmod +x /usr/local/bin/fly

RUN curl --retry 30 -SL "https://codeclimate.com/downloads/test-reporter/test-reporter-latest-linux-amd64" -o /usr/local/bin/cc-test-reporter \
  && chmod a+x /usr/local/bin/cc-test-reporter

RUN curl --retry 30 -SL "https://raw.githubusercontent.com/ekalinin/github-markdown-toc/master/gh-md-toc" -o /usr/local/bin/gh-md-toc \
  && chmod a+x /usr/local/bin/gh-md-toc

# Download BOSH v2 CLI
RUN curl --retry 30 -SLo /usr/local/bin/bosh https://s3.amazonaws.com/bosh-cli-artifacts/bosh-cli-${BOSH_CLI_VERSION}-linux-amd64 \
  && echo "Computed sha256sum: $(sha256sum /usr/local/bin/bosh)" \
  && echo "${BOSH_CLI_SHA256} */usr/local/bin/bosh" | shasum -a 256 -c - \
  && chmod +x /usr/local/bin/bosh

# remove old version of bundler to avoid confusion between bundler and bundle cmd
#   bundler => old binary
#   bundle => latest binary
RUN rm -f /usr/local/bundle/bin/bundler

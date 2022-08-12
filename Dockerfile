FROM ruby:3.1.2

# c264d9cb979d05598e44e0527220e21e2f20564f63cc11f98c8480768997433f  fly-7.6.0-linux-amd64.tgz
# 92c56cb432c5d86d8687d765bd6d0847dc80edfbab28a878a9c11eec9289b02d  fly-7.8.2-linux-amd64.tgz
# https://github.com/concourse/concourse/releases/
ARG CONCOURSE_VERSION=7.8.2
ARG CONCOURSE_SHA256=92c56cb432c5d86d8687d765bd6d0847dc80edfbab28a878a9c11eec9289b02d

# https://github.com/cloudfoundry/bosh-cli/releases
ARG BOSH_CLI_VERSION=6.4.17
ARG BOSH_CLI_SHA256=d0917d3ad0ff544a4c69a7986e710fe48e8cb2207717f77db31905d639e28c18

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
  && echo "${BOSH_CLI_SHA256} */usr/local/bin/bosh" | shasum -a 256 -c - \
  && chmod +x /usr/local/bin/bosh

# remove old version of bundler to avoid confusion between bundler and bundle cmd
#   bundler => old binary
#   bundle => latest binary
RUN rm -f /usr/local/bundle/bin/bundler

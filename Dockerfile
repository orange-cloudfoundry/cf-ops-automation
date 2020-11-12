FROM ruby:2.6.3

# 3791e5703717a074429311d2d218c234a270f5b358210b6bb722b684dc1b5153  fly-5.8.1-linux-amd64.tgz
# 28d59035d87157f3e87496c2350deefebbe050baed3fcc7f968605fa144bb11e  fly-6.4.0-linux-amd64.tgz
# 16d27cf2c416f6fbcd993e6e9ac01fc67200b8d173048ca44ddced10faa8a8b7  fly-6.5.1-linux-amd64.tgz
# 6d07d253008ec58417323d62d944032ff2fabe362b850da89582dd9aa2f61cf9  fly-6.7.1-linux-amd64.tgz
ARG CONCOURSE_VERSION=6.7.1
ARG CONCOURSE_SHA256=6d07d253008ec58417323d62d944032ff2fabe362b850da89582dd9aa2f61cf9

ARG BOSH_CLI_VERSION=6.2.1
ARG BOSH_CLI_SHA256=ca7580008abfd4942dcb1dd6218bde04d35f727717a7d08a2bc9f7d346bce0f6

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

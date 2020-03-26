FROM ruby:2.6.3

# 3791e5703717a074429311d2d218c234a270f5b358210b6bb722b684dc1b5153  fly-5.8.1-linux-amd64.tgz
# 3df15b9c3e342eb41d6b3192e89459e304e996af2a61e5788418f8d74645e665  fly-5.8.0-linux-amd64.tgz
# d9b93f792b5ed77d785f192da9710d5da788d042a52f352e52e310f32a9f8e87  fly-5.3.0-linux-amd64.tgz
ARG CONCOURSE_VERSION=5.8.0
ARG CONCOURSE_SHA=3791e5703717a074429311d2d218c234a270f5b358210b6bb722b684dc1b5153

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
  && [ ${CONCOURSE_SHA} = $(sha256sum /tmp/fly.tgz | cut -d' ' -f1) ] \
  && cd /tmp \
  && tar xzvf /tmp/fly.tgz \
  && mv /tmp/fly /usr/local/bin/fly \
  && chmod +x /usr/local/bin/fly

RUN curl --retry 30 -SL "https://codeclimate.com/downloads/test-reporter/test-reporter-latest-linux-amd64" -o /usr/local/bin/cc-test-reporter \
  && chmod a+x /usr/local/bin/cc-test-reporter

RUN curl --retry 30 -SL "https://raw.githubusercontent.com/ekalinin/github-markdown-toc/master/gh-md-toc" -o /usr/local/bin/gh-md-toc \
  && chmod a+x /usr/local/bin/gh-md-toc

# Download BOSH v2 CLI
RUN curl --retry 30 -SLo /usr/local/bin/bosh https://s3.amazonaws.com/bosh-cli-artifacts/bosh-cli-3.0.1-linux-amd64 \
  && echo "58e6853291c3535e77e5128af9f0e8e4303dd57e5a329aa976f197c010517975 */usr/local/bin/bosh" | shasum -a 256 -c - \
  && chmod +x /usr/local/bin/bosh

# remove old version of bundler to avoid confusion between bundler and bundle cmd
#   bundler => old binary
#   bundle => latest binary
RUN rm -f /usr/local/bundle/bin/bundler

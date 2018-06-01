FROM ruby:2.3.1

ARG CONCOURSE_VERSION
ARG CONCOURSE_SHA

RUN apt-get update && \
 apt-get install tree

# install cf-ops-automation Gemfile
RUN gem update --system
RUN gem install bundler
COPY Gemfile /usr/local/Gemfile
COPY Gemfile.lock /usr/local/Gemfile.lock
RUN cd /usr/local && bundle install

# install fly-cli
RUN curl -sfL "https://github.com/concourse/concourse/releases/download/v${CONCOURSE_VERSION}/fly_linux_amd64" -o /usr/local/bin/fly \
  && [ ${CONCOURSE_SHA} = $(shasum -a 256 /usr/local/bin/fly | cut -d' ' -f1) ] \
  && chmod +x /usr/local/bin/fly

RUN curl -sfL "https://codeclimate.com/downloads/test-reporter/test-reporter-latest-linux-amd64" > /usr/local/bin/cc-test-reporter \
  && chmod a+x /usr/local/bin/cc-test-reporter

RUN curl -sfL "https://raw.githubusercontent.com/ekalinin/github-markdown-toc/master/gh-md-toc" > /usr/local/bin/gh-md-toc \
  && chmod a+x /usr/local/bin/gh-md-toc

RUN curl -sfL "https://github.com/starkandwayne/bucc/archive/v0.5.0.tar.gz" > bucc.tar.gz \
  && tar -xzf bucc.tar.gz \
  && cp bucc-0.5.0/bin/bucc /usr/local/bin/bucc \
  && chmod a+x /usr/local/bin/bucc \
  && rm -rf bucc.tar.gz bucc-0.5.0

# Download BOSH v2 CLI
RUN curl -o /usr/local/bin/bosh https://s3.amazonaws.com/bosh-cli-artifacts/bosh-cli-3.0.1-linux-amd64 \
  && echo "58e6853291c3535e77e5128af9f0e8e4303dd57e5a329aa976f197c010517975 */usr/local/bin/bosh" | shasum -a 256 -c - \
  && chmod +x /usr/local/bin/bosh

# remove old version of bundler to avoid confusion between bundler and bundle cmd
#   bundler => old binary
#   bundle => latest binary
RUN rm -f /usr/local/bundle/bin/bundler

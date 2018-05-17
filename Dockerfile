FROM ruby:2.3.1

ARG CONCOURSE_VERSION
ARG CONCOURSE_SHA


# install cf-ops-automation Gemfile
RUN gem update --system
RUN gem install bundler
COPY Gemfile /usr/local/Gemfile
COPY Gemfile.lock /usr/local/Gemfile.lock
RUN cd /usr/local && bundle install

#install fly-cli
RUN curl "https://github.com/concourse/concourse/releases/download/v${CONCOURSE_VERSION}/fly_linux_amd64" -sfL -o /usr/local/bin/fly \
  && [ ${CONCOURSE_SHA} = $(shasum -a 256 /usr/local/bin/fly | cut -d' ' -f1) ] \
  && chmod +x /usr/local/bin/fly

RUN curl -L "https://codeclimate.com/downloads/test-reporter/test-reporter-latest-linux-amd64" > /usr/local/bin/cc-test-reporter \
  && chmod a+x /usr/local/bin/cc-test-reporter

RUN curl -L "https://raw.githubusercontent.com/ekalinin/github-markdown-toc/master/gh-md-toc" > /usr/local/bin/gh-md-toc \
  && chmod a+x /usr/local/bin/gh-md-toc

# remove old version of bundler to avoid confusion between bundler and bundle cmd
#   bundler => old binary
#   bundle => latest binary
RUN rm -f /usr/local/bundle/bin/bundler
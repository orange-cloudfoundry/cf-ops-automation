FROM ruby:2.3.1

ARG CONCOURSE_VERSION
ARG CONCOURSE_SHA


# install cf-ops-automation Gemfile
# There is an error with rubygems 2.7.0 and 2.7.1. Don't do a gem update --system unless a new version fix it
#RUN gem update --system
RUN gem install bundler
COPY Gemfile /usr/local/Gemfile
COPY Gemfile.lock /usr/local/Gemfile.lock
RUN cd /usr/local && bundle install

#install fly-cli
RUN curl "https://github.com/concourse/concourse/releases/download/v${CONCOURSE_VERSION}/fly_linux_amd64" -sfL -o /usr/local/bin/fly \
  && [ ${CONCOURSE_SHA} = $(shasum -a 256 /usr/local/bin/fly | cut -d' ' -f1) ] \
  && chmod +x /usr/local/bin/fly

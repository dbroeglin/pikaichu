FROM ruby:3.0.3-slim-bullseye

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    libpq-dev \
    postgresql-client \
    nodejs npm \
    git \
    && npm install -g yarn \
    && gem update --system \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# use a global path instead of vendor
ENV GEM_HOME="/usr/local/bundle"
ENV BUNDLE_PATH="$GEM_HOME"
ENV BUNDLE_SILENCE_ROOT_WARNING=1
ENV BUNDLE_DEPLOYMENT=1
ENV BUNDLE_APP_CONFIG="$GEM_HOME"
ENV BUNDLE_WITHOUT='development:test'
ENV PATH="$GEM_HOME/bin:$BUNDLE_PATH/gems/bin:${PATH}"
ENV RAILS_ENV=production
ENV RAILS_SERVE_STATIC_FILES=true
ENV PORT=80

# make 'docker logs' work
ENV RAILS_LOG_TO_STDOUT=true

# copy the source
WORKDIR /app
COPY . /app
RUN rm -f tmp/pids/server.pid
RUN mkdir -p tmp/pids
RUN bundle install -j4
RUN bin/rails assets:precompile

# build and start
CMD bundle exec puma -C config/puma.rb
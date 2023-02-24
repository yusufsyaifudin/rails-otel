FROM ruby:3-bullseye

RUN apt-get update -qq

# Set workdir to "myapp"
WORKDIR /myapp

# Copy Gemfile and download all Gem required to run.
# This minimize the build time because `bundle` doesn't need to scan all source code.
COPY Gemfile /myapp/Gemfile
COPY Gemfile.lock /myapp/Gemfile.lock
RUN bundle install

# Add a script to be executed every time the container starts.
COPY entrypoint.sh /usr/bin/
RUN chmod +x /usr/bin/entrypoint.sh
EXPOSE 3000

ENTRYPOINT ["entrypoint.sh"]

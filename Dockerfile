FROM ruby:2.4

ENV RAILS_ENV=production \
    HELPY_HOME=/helpy \
    HELPY_USER=helpyuser \
    HELPY_SLACK_INTEGRATION_ENABLED=true

RUN apt-get update \
  && apt-get upgrade -y \
  && apt-get install -y nodejs postgresql-client imagemagick --no-install-recommends \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

RUN useradd --no-create-home $HELPY_USER \
  && mkdir -p $HELPY_HOME \
  && chown -R $HELPY_USER:$HELPY_USER $HELPY_HOME /usr/local/lib/ruby /usr/local/bundle

WORKDIR $HELPY_HOME

COPY Gemfile Gemfile.lock $HELPY_HOME/
COPY vendor $HELPY_HOME/vendor
RUN chown -R $HELPY_USER $HELPY_HOME

USER $HELPY_USER


# add the slack integration gem to the Gemfile if the HELPY_SLACK_INTEGRATION_ENABLED is true
# use `test` for sh compatibility, also use only one `=`. also for sh compatibility
RUN test "$HELPY_SLACK_INTEGRATION_ENABLED" = "true" \
    && sed -i '128i\gem "helpy_slack", git: "https://github.com/helpyio/helpy_slack.git", branch: "master"' $HELPY_HOME/Gemfile

RUN bundle install

RUN touch /helpy/log/production.log && chmod 0664 /helpy/log/production.log

# Due to a weird issue with one of the gems, execute this permissions change:
RUN chmod +r /usr/local/bundle/gems/griddler-mandrill-1.1.4/lib/griddler/mandrill/adapter.rb

# manually create the /helpy/public/assets folder and give the helpy user rights to it
# this ensures that helpy can write precompiled assets to it
RUN mkdir -p $HELPY_HOME/public/assets \
    && chown $HELPY_USER $HELPY_HOME/public/assets

VOLUME $HELPY_HOME/public

USER root
COPY . $HELPY_HOME/
RUN chown -R $HELPY_USER $HELPY_HOME
USER $HELPY_USER

COPY docker/database.yml $HELPY_HOME/config/database.yml
COPY docker/run.sh $HELPY_HOME/run.sh

CMD ["./run.sh"]

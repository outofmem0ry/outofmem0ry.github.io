FROM jekyll/jekyll

COPY --chown=jekyll:jekyll Gemfile .
COPY --chown=jekyll:jekyll Gemfile.lock .
#COPY --chown=jekyll:jekyll . /srv/jekyll

RUN bundle install --quiet --clean

CMD ["jekyll", "serve"]
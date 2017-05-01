FROM ruby:2.2
RUN mkdir -p /scenario
WORKDIR /scenario
ENV LANG=C.UTF-8
CMD bundle install && bundle exec rake

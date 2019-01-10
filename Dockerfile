FROM ruby:2.6.0

RUN gem install bundler --pre

RUN mkdir app
COPY Gemfile* /app/
RUN cd /app && bundle install -j6 --without=development --frozen

ADD . /app/
WORKDIR /app

ENTRYPOINT ["sh", "-c"]

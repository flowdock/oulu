FROM ruby:2.1.4

WORKDIR /app

COPY Gemfile* ./
RUN bundle install

COPY . .

ENV PORT=5000
ENTRYPOINT [ "/app/entrypoint.sh" ]

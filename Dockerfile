FROM ruby:2.7.0 as ruby

WORKDIR /app
COPY Gemfile* /app/
RUN bundle config --local deployment 'true'
RUN bundle config --local frozen 'true'
RUN bundle config --local no-cache 'true'
RUN bundle config --local clean 'true'
RUN bundle config --local without 'development'
RUN bundle config --local path 'vendor/bundle'
RUN bundle install
RUN mkdir .bundle && cp /usr/local/bundle/config .bundle/config
RUN rm -rf vendor/bundle/ruby/2.7.0/cache vendor/bundle/ruby/2.7.0/bin


FROM gcr.io/distroless/base-debian10 as distroless

COPY --from=ruby /lib/x86_64-linux-gnu/libz.so.* /lib/x86_64-linux-gnu/
COPY --from=ruby /usr/lib/x86_64-linux-gnu/libyaml* /usr/lib/x86_64-linux-gnu/
COPY --from=ruby /usr/lib/x86_64-linux-gnu/libgmp* /usr/lib/x86_64-linux-gnu/
COPY --from=ruby /usr/local/lib /usr/local/lib
COPY --from=ruby /usr/local/bin/ruby /usr/local/bin/ruby
COPY --from=ruby /usr/local/bin/bundle /usr/local/bin/bundle


FROM scratch

COPY --from=ruby /app /app

COPY --from=distroless /lib /lib
COPY --from=distroless /lib64 /lib64
COPY --from=distroless /usr/local /usr/local
COPY --from=distroless /usr/lib/ssl /usr/lib/ssl
COPY --from=distroless /usr/lib/x86_64-linux-gnu/lib* /usr/lib/x86_64-linux-gnu/
COPY --from=distroless /etc/ssl /etc/ssl
COPY --from=distroless /home /home

WORKDIR /app
COPY dialogs /app/dialogs/
COPY services /app/services/
COPY *.rb /app/

ENV SSL_CERT_FILE /etc/ssl/certs/ca-certificates.crt
ENV RUBYOPT -W:no-deprecated -W:no-experimental

CMD ["bundle", "exec", "ruby", "server.rb"]

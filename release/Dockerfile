FROM frolvlad/alpine-glibc:alpine-3.4
MAINTAINER Bjoern Lichtblau <lightblu@github>

RUN apk --update add --no-cache gmp && rm -rf /tmp/* /var/cache/apk/*

# Add backend files
COPY ./hermodr /usr/local/bin/hermodr

### Prometheus metrics
EXPOSE 8080

CMD ["/usr/local/bin/hermodr"]

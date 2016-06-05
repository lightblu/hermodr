FROM alpine:3.3
MAINTAINER Bjoern Lichtblau <lightblu@github>

# Add backend files
COPY ./hermodr /usr/local/bin/hermodr

### Prometheus metrics
EXPOSE 8080

CMD ["/usr/local/bin/hermodr"]

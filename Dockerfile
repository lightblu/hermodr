FROM library/haskell:7.10.3
MAINTAINER Bjoern Lichtblau <lightblu@github>

# Set correct environment variables.
ENV HOME /root

# Install these directly, compiling own BLAS/LAPACK is hairy

RUN cabal update

RUN apt-get update && apt-get install nano

# Add backend files
COPY . /opt/hermodr

###
WORKDIR /opt/hermodr

RUN cd /opt/hermodr && \
    cabal sandbox init && \
    cabal install --dependencies-only && \
    cabal build && \
    strip dist/build/hermodr/hermodr

### Prometheus metrics
EXPOSE 8080

CMD ["./run"]

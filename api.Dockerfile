FROM ghcr.io/gleam-lang/gleam:v0.34.1-elixir-alpine

COPY gleam.toml manifest.toml ./

COPY ./src ./src

COPY ./priv ./priv

# Add build dependencies
RUN apk add --no-cache gcc build-base libc-dev

RUN mix local.hex --force

RUN gleam export erlang-shipment && \
  mv build/erlang-shipment /app

WORKDIR /app

# Run the application
ENTRYPOINT ["/app/entrypoint.sh"]
CMD ["run"]

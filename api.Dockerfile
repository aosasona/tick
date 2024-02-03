FROM ghcr.io/gleam-lang/gleam:v0.34.1-elixir-slim

COPY gleam.toml manifest.toml ./

COPY ./src ./src

COPY ./priv ./priv

# # Add build dependencies - Elixir, Erlang and things required to build NIFs
# RUN apk add --no-cache gcc build-base libc-dev

RUN mix local.hex --force

RUN gleam export erlang-shipment && \
  mv build/erlang-shipment /app

WORKDIR /app

# Run the application
ENTRYPOINT ["/app/entrypoint.sh"]
CMD ["run"]

####### Build frontend
FROM node:20-alpine AS build-fe

WORKDIR /app

RUN npm install -g pnpm

COPY ./ui/package.json ./ui/pnpm-lock.yaml ./

RUN pnpm install

COPY ./ui ./

RUN pnpm build


####### Build backend and merge with frontend
FROM ghcr.io/gleam-lang/gleam:v0.34.1-elixir-alpine as build-gleam

COPY gleam.toml manifest.toml ./

COPY ./src ./src

COPY ./priv ./priv

RUN mkdir -p priv/web

COPY --from=build-fe /app/dist ./priv/web

# Add build dependencies - Elixir, Erlang and things required to build NIFs
RUN apk add --no-cache gcc build-base libc-dev

RUN mix local.hex --force

RUN gleam export erlang-shipment && \
  mv build/erlang-shipment /app


######### Build release image
FROM ghcr.io/gleam-lang/gleam:v0.34.1-erlang-alpine

WORKDIR /app

# Copy the Gleam application
COPY --from=build-gleam /app .

# Run the application
ENTRYPOINT ["/app/entrypoint.sh"]
CMD ["run"]

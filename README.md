# Tick 📝

A simple demo of a local-first todo application (with auth). The front-end is a Solid.js app that can be served as a PWA separately and the backend is a Gleam-based API using patterns found in something like Rust's Axum instead of the normal Wisp pattern of returning responses straight.

## Setup

- Copy the environment variables and make any adjustment you want to make

```sh
cp .env.example .env
```

Follow any of the steps below to get it running:

### Deploying separately (recommended)

To deploy the frontend separately as a Progressive Web App (PWA) that can be installed on devices for an offline experience, point your hosting service at the `ui` folder and use the included `api.Dockerfile` to deploy the API.

### Deploying together

To serve the Solid.js and API from the same server, you can use the included Dockerfile (will build and serve both) or run:

```sh
pnpm start:prod
```

### Development

- Run the server

```sh
pnpm dev:api
```

- Start the solid.js frontend

```sh
pnpm dev:ui
```

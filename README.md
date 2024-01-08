# tick
Local-first realtime todo list demo in Gleam, Solid.js and SQlite

This is not designed to be fully secure, hence the presence of "anomalies" like the storage of auth tokens in the browser where it is directly accessible with Javascript. Please do not store private data with this application.

> This document is also mainly a rough draft, you probably want to look at the code instead

## Architecture

This is the main reason for making this repository; to explore making real-time local software. The app is split in two parts like every other app these days but with a distinction we will discover as we proceed; the server and the client, let's talk about the roles they both play now.

### Server

The server here serves two purpose:
- `authentication`: this is mainly to control access to the websocket endpoint that is heavily used here
- `remote state tracking`: I know this sounds fancy but this essentially means that our server doesn't store data in the traditional sense, in fact, it doesn't really know what your data is, it stores logs/events that are then used by clients to construct their own data.

In the real sense, we barely have any REST-y endpoint here outside sign up and sign in, the reason is because we communicate via events, we'll dive into this deeper.

### Client
Well, it is in the name, this is the part the user interacts with primarily. While we do have a server, every operation the user performs should and would ideally take place locally first (I mean, that is thw whole point of this.

## Events

Events are how the client and server "communicate" here. An event would often be in this format:
```json
{
  op: number,
  d: object
}
```

> numbers are used for event codes to reduce the payload size, inspired by the usage in the Hop Leap protocol (https://docs.hop.io/other-products/channels/internals/leap)

> The client also stores logs for operations that are performed offline; all logs are removed after they are acknowledged by the server - this is a LRW (Last Write Wins) system, doesn't matter if the server or a client had the last write 

 Examples of `op`s are:
 
 > format: `event  name` (op code, emitted by)
 
 - `server_sync` (1, server): When a server is ready to receive logs from the client, often sent like few seconds after the client joins - often sent before the client syncs
 - `client_sync` (2, client): When a client starts up and is able to reach out to the server, this is usually accompanied by the timestamp of the last sync event received from the server - the server starts streaming in logs which are then used by the client to reconstruct its own data

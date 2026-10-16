# Iguana X Log API Example

Lua example that authenticates to Iguana X, retrieves component error logs and component details, then queues a JSON result.

## Workflow

`Input component → login → retrieve logs and details → logout → queue result`

The component fields configure `base_url`, `username`, and `password`. Input has one field: `component`, containing the identifier expected by your Iguana X instance.

## Setup

Requires Iguana X APIs: `component.fields`, `net.http`, `json`, and `queue`. Use `src/config.json` as the component field definitions and `src/main.lua` as the source. Configure credentials through protected component fields and use HTTPS for remote instances.

## Output

The queued object contains `logs` (up to five matching error records, in API order) and `component` (the component-detail response). The example does not assume which log is newest. Empty results produce an empty logs collection.

## Run local unit tests

From this repository directory, use Lua 5.4:

```sh
lua tests/session_test.lua
```

These tests use synthetic fixtures and mocked Iguana APIs. They do not replace testing inside Iguana.

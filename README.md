# Iguana X Log API Example

Lua example that authenticates to Iguana X, retrieves component error logs and component details, then queues a JSON result.

## Workflow

`Input component → login → retrieve logs and details → logout → queue result`

The component fields configure `base_url`, `username`, and `password`. Input has one field: `component`, containing the identifier expected by your Iguana X instance. No original input messages are included.

## Setup

Requires Iguana X APIs: `component.fields`, `net.http`, `json`, and `queue`. Use `src/config.json` as the component field definitions and `src/main.lua` as the source. Configure credentials through protected component fields and use HTTPS for remote instances.

## Output

The queued object contains `logs` (up to five matching error records, in API order) and `component` (the component-detail response). The example does not assume which log is newest. Empty results produce an empty logs collection.

## Cleanup and validation

Added configurable base URL, HTTP-status checks, input checks, empty-log handling, and logout attempts after retrieval errors. Removed assumptions about the latest log and avoided logging credentials, cookies, or API response bodies. Error messages are deliberately generic to avoid exposing responses. Queue output still contains operational log data; handle it appropriately in the downstream channel.

Mock tests cover success, empty results, and logout after retrieval failure. Actual Iguana X endpoints and response formats have not been tested here. This is source code, not a complete exported component.

## Run local unit tests

From this repository directory, use Lua 5.4:

```sh
lua tests/session_test.lua
```

These tests use synthetic fixtures and mocked Iguana APIs. They do not replace testing inside Iguana.

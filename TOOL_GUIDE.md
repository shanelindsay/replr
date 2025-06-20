# replr Tool Guide

This guide summarizes the command line helpers and R functions for interacting
with `replr`'s local HTTP server. Console text is returned unless you request
JSON.

## R helper functions

The package exposes a few core functions:

- `start_server(port = 8080, host = "127.0.0.1", background = FALSE)` — launches the JSON server. If
  `background = TRUE` the call returns immediately with the server running in
the background.
- `stop_server(port = 8080)` — sends a shutdown request to the server.
- `exec_code(code, port = 8080, plain = TRUE, summary = FALSE, output = TRUE,
  warnings = TRUE, error = TRUE)` — submit R code to the running server and
  return plain text. Set `plain = FALSE` for parsed JSON output.
- `server_status(port = 8080)` — retrieve basic information such as uptime and
  process id.

### Global options

The preview length for summaries is controlled by `replr.preview_rows`.
It defaults to `5`. Set `options(replr.preview_rows = n)` before sending
commands to adjust how many rows are shown in previews.

## Bash command line (tools/clir.sh)

The `tools` directory contains small clients for shells. The Bash script
`clir.sh` requires `jq` for encoding JSON and provides several subcommands:

```bash
clir.sh start [label] [port] [host]     # start server and record instance
clir.sh stop [label] [host]             # stop the labelled instance
clir.sh status [label] [host]           # query status of instance
clir.sh exec [label] [-e CODE] [--json] [host]  # execute code (or pipe via stdin)

clir.sh list                     # list known instances
```

To omit warnings or errors from the JSON output, include query parameters when
calling the endpoint directly:

```bash
curl -s -X POST -H "Content-Type: application/json" \
  -d '{"command":"warning(\"a\")"}' \
  "http://127.0.0.1:8080/execute?warnings=false"
```

Instances are tracked under `~/.replr/instances`. Labels default to
`"default"` and ports default to `8080`. Examples:

```bash
# start a server on port 8123 and label it mysrv
clir.sh start mysrv 8123 127.0.0.1

# run a single command
clir.sh exec mysrv -e '1+1'
# JSON output
clir.sh exec mysrv -e '1+1' --json

# check status
clir.sh status mysrv 127.0.0.1

# stop the server
clir.sh stop mysrv 127.0.0.1
```

## Python and PowerShell

- `tools/clir.py` provides minimal equivalents written in Python using the
  `requests` library.
- `tools/clir.ps1` is a PowerShell helper for Windows environments.

Both allow executing code and checking server status from other scripting
languages.

## Workflow overview

1. Use `start_server()` in R or `clir.sh start` to launch the server.
2. Send R code with `exec_code()` or via the command line tools.
3. Use `--json` with the CLI if you need structured data. Plain text is
   returned otherwise. JSON includes captured output, warnings, errors,
   and plot paths. Summaries are returned for common result types
   (data frames, model objects, etc.).
4. Stop the server when done with `stop_server()` or `clir.sh stop`.

This lightweight interface lets you drive R sessions from other processes or
scripts without relying on interactive sessions.

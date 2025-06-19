# replr Tool Guide

This guide summarizes the command line helpers and R functions for interacting with
`replr`'s local HTTP server. The README and vignette provide more detail;
this file focuses on available commands and options.

## R helper functions

The package exposes a few core functions:

- `start_server(port = 8080, background = FALSE)` — launches the JSON server. If
  `background = TRUE` the call returns immediately with the server running in
the background.
- `stop_server(port = 8080)` — sends a shutdown request to the server.
- `exec_code(code, port = 8080, plain = FALSE, summary = TRUE, output = TRUE,
  warnings = TRUE, error = TRUE)` — submit R code to the running server and
  return the parsed JSON response. By default warnings and errors are captured
  so the JSON mimics interactive R evaluation. Set `warnings = FALSE` or
  `error = FALSE` to suppress them. Setting `plain = TRUE` returns plain text.
- `server_status(port = 8080)` — retrieve basic information such as uptime and
  process id.

## Bash command line (tools/clir.sh)

The `tools` directory contains small clients for shells. The Bash script
`clir.sh` provides several subcommands:

```bash
clir.sh start [label] [port]     # start server and record instance
clir.sh stop [label]             # stop the labelled instance
clir.sh status [label]           # query status of instance
clir.sh exec [label] -e CODE     # execute code (or pipe via stdin)
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
clir.sh start mysrv 8123

# run a single command
clir.sh exec mysrv -e '1+1'

# check status
clir.sh status mysrv

# stop the server
clir.sh stop mysrv
```

## Python and PowerShell

- `tools/clir.py` provides minimal equivalents written in Python using the
  `requests` library.
- `tools/clir.ps1` is a PowerShell helper for Windows environments.

Both allow executing code and checking server status from other scripting
languages.

## Workflow overview

1. Use `start_server()` in R or `clir.sh start` to launch the JSON server.
2. Send R code with `exec_code()` or via the command line tools.
3. Inspect results in JSON form, including captured output, warnings, errors,
   and plot paths. Summaries are returned for common result types
   (data frames, model objects, etc.).
4. Stop the server when done with `stop_server()` or `clir.sh stop`.

This lightweight interface lets you drive R sessions from other processes or
scripts without relying on interactive sessions.

# rjsonsrv Tool Guide

This guide summarizes the command line helpers and R functions for interacting with
`rjsonsrv`'s local HTTP server. The README and vignette provide more detail;
this file focuses on available commands and options.

## R helper functions

The package exposes a few core functions:

- `start_server(port = 8080, background = FALSE)` — launches the JSON server. If
  `background = TRUE` the call returns immediately with the server running in
the background.
- `stop_server(port = 8080)` — sends a shutdown request to the server.
- `exec_code(code, port = 8080, plain = FALSE, summary = TRUE, output = TRUE,
  warnings = TRUE, error = TRUE)` — submit R code to the running server and
  return the parsed JSON response. Setting `plain = TRUE` returns plain text.
- `server_status(port = 8080)` — retrieve basic information such as uptime and
  process id.

## Bash command line (tools/rcli.sh)

The `tools` directory contains small clients for shells. The Bash script
`rcli.sh` provides several subcommands:

```bash
rcli.sh start [label] [port]     # start server and record instance
rcli.sh stop [label]             # stop the labelled instance
rcli.sh status [label]           # query status of instance
rcli.sh exec [label] -e CODE     # execute code (or pipe via stdin)
rcli.sh list                     # list known instances
```

Instances are tracked under `~/.rjson/instances`. Labels default to
`"default"` and ports default to `8080`. Examples:

```bash
# start a server on port 8123 and label it mysrv
rcli.sh start mysrv 8123

# run a single command
rcli.sh exec mysrv -e '1+1'

# check status
rcli.sh status mysrv

# stop the server
rcli.sh stop mysrv
```

## Python and PowerShell

- `tools/rcli.py` provides minimal equivalents written in Python using the
  `requests` library.
- `tools/rcli.ps1` is a PowerShell helper for Windows environments.

Both allow executing code and checking server status from other scripting
languages.

## Workflow overview

1. Use `start_server()` in R or `rcli.sh start` to launch the JSON server.
2. Send R code with `exec_code()` or via the command line tools.
3. Inspect results in JSON form, including captured output, warnings, errors,
   and plot paths. Summaries are returned for common result types
   (data frames, model objects, etc.).
4. Stop the server when done with `stop_server()` or `rcli.sh stop`.

This lightweight interface lets you drive R sessions from other processes or
scripts without relying on interactive sessions.


# replr

**replr** provides a simple HTTP server for evaluating R code. By default it
returns the console output from the expression. Set `plain = FALSE` or pass
`--json` on the CLI to receive structured JSON instead. This is useful for
small automation tasks or remote evaluation from other languages.

## Installation with micromamba

1. Create the `myr` environment using the provided `environment.yml`.
   This file lists required R packages such as `r-httpuv` and `r-jsonlite` used
   by the server.
   ```bash
   micromamba env create -f environment.yml
   ```
2. Activate the environment:
   ```bash
   micromamba activate myr
   ```
3. Install the package from GitHub:
  ```R

 devtools::install_github("shanelindsay/replr")
  ```
4. Install Python requirements for the optional CLI tool:
   ```bash
   pip install -r requirements.txt
   ```
5. Install `jq`, required by `clir.sh` for encoding JSON:
   ```bash
   sudo apt-get install jq  # or use your package manager
   ```

## Basic usage

Start the server and execute some code:

```R
library(replr)

start_server(port = 8080, host = "127.0.0.1", background = TRUE)

# returns console text
exec_code("1 + 1", port = 8080)
## [1] 2

# request JSON instead
exec_code("1 + 1", port = 8080, plain = FALSE)
## {
##   "output": "[1] 2",
##   "error": "",
##   "plots": "",
##   "result_summary": {"type": "double"}
## }
```

Use `server_status()` to confirm the server is running, and `stop_server()` to shut it down.

### Returning full results

`exec_code()` returns plain text by default. Set `plain = FALSE` to obtain a
parsed JSON response. Use `summary = TRUE` or `full_results = TRUE` to request
additional detail from the server.

### Controlling warnings and errors

By default the server captures any warnings and errors just as they would
appear in an interactive R session. These messages are returned in the JSON
response under the `warning` and `error` fields. To silence them you can set
`warnings = FALSE` or `error = FALSE`:

```R
exec_code("warning('oops'); 1", port = 8080, warnings = FALSE)
exec_code("log('foo')", port = 8080, error = FALSE)
```

When using `curl` directly you can pass query parameters:

```bash
curl -s -X POST -H "Content-Type: application/json" \
  -d '{"command":"warning(\"hi\");1"}' \
  "http://127.0.0.1:8080/execute?warnings=false"
```

## Starting and stopping the server

Launch a background server on a custom port:

```R
start_server(port = 8080, host = "127.0.0.1", background = TRUE)
```

Stop that server instance when finished:

```R
stop_server(port = 8080)
```

The same operations can be performed from the command line:

```bash
tools/clir.sh start default 8080 127.0.0.1
tools/clir.sh stop 8080 127.0.0.1
```

## Running tests

After activating the `myr` environment, run the unit tests with:

```bash
micromamba activate myr
R -q -e "devtools::test()"
```

## Command line usage

Evaluate a single expression directly from the shell using the `--command`
option. Quote the expression so it is passed as one argument:

```bash
replr --command "1 + 1"           # plain text output
#> [1] 2

# request JSON
replr --command "1 + 1" --json
#> {"output":"[1] 2","error":"","plots":"","result_summary":{"type":"double"}}
```

### Global options

`replr` uses a few R options for customization. The number of rows shown in
data frame summaries is controlled by `replr.preview_rows` which defaults to `5`.
Set this option before starting the server (or via `exec_code()` once running)
to change how many rows are returned in previews.

## Building and checking the package

Use `tools/release_cran.R` to build a source tarball and run `R CMD check`.
Ensure the `myr` environment is active so all dependencies are available.

```bash
micromamba activate myr
Rscript tools/release_cran.R
```

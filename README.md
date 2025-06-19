# replr

**replr** provides a simple HTTP server for evaluating R code and returning structured JSON results. It is designed for small automation tasks or remote evaluation from other languages.

## Installation with micromamba

1. Create the `myr` environment using the provided `environment.yml`:
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

## Basic usage

Start the server and execute some code:

```R
library(replr)

start_server(port = 8080, background = TRUE)

exec_code("1 + 1", port = 8080)
```

Use `server_status()` to confirm the server is running, and `stop_server()` to shut it down.

### Returning full results

`exec_code()` normally returns a summary of the evaluated object. Set
`full_results = TRUE` to include the entire object in the JSON response.
Be mindful that this may expose sensitive data or generate very large
responses.

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
replr --command "1 + 1"
```


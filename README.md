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
#> [1] 2
```

Use `server_status()` to confirm the server is running, and `stop_server()` to shut it down.

### Returning full results

`exec_code()` returns plain text by default. Set `plain = FALSE` to obtain a
parsed JSON response. Use `summary = TRUE` or `full_results = TRUE` to request
additional detail from the server.

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


# rjsonsrv

**rjsonsrv** provides a simple HTTP server for evaluating R code and returning structured JSON results. It is designed for small automation tasks or remote evaluation from other languages.

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
library(rjsonsrv)

start_server(port = 8080, background = TRUE)

exec_code("1 + 1", port = 8080)
```

Use `server_status()` to confirm the server is running, and `stop_server()` to shut it down.

## Running tests

After activating the `myr` environment, run the unit tests with:

```bash
micromamba activate myr
R -q -e "devtools::test()"
```


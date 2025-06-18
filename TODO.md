# TODO

- Add more comprehensive tests for server behaviors and error handling.
- Implement S3 helpers for rjson responses beyond `as_tibble()`.
- ~~Write README documentation explaining usage and installation.~~ (completed)
- ~~Ensure `httr` dependency is listed and included.~~ (completed)
- Package and distribution scripts for CRAN or pip.

- Add GitHub Actions workflow for automated testing.
- Provide R helper and CLI command for the `/state` endpoint.
- Use `httpuv::runServer()` with `later` for the heartbeat to avoid busy waiting.
- Introduce an S3 generic `summary_json()` for customizable result summaries and
  assign the `rjson_response` class in `exec_code()` so helpers like
  `as_tibble()` dispatch correctly.

as_tibble.rjson_response <- function(x, ...) {
  if (!requireNamespace("tibble", quietly = TRUE)) stop("Install tibble")
  tibble::tibble(
    output = x$output,
    error = x$error,
    warning = list(x$warning),
    result_summary = list(x$result_summary),
    plots = list(x$plots)
  )
}

#' Convert a JSON response to a tibble
#'
#' Helper for turning the structured JSON response from the server into a
#' `tibble`. Requires the tibble package to be installed.
#'
#' @param x An object of class `rjson_response` returned by `exec_code()`.
#' @param ... Additional arguments ignored.
#' @return A `tibble` with columns `output`, `error`, `warning`,
#'   `result_summary`, and `plots`.
#' @method as_tibble rjson_response
#' @export
#' @importFrom tibble as_tibble
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

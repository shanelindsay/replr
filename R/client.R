#' Execute code on the replr server
#'
#' Sends R expressions to a running `replr` server. By default the result is
#' returned as plain text. Set `plain = FALSE` to receive parsed JSON. Use
#' `full_results = TRUE` to include the complete result object in the response.
#'
#' @param code Character string of R code to evaluate.
#' @param port Server port number.
#' @param plain Logical; return plain text (default) or JSON when `FALSE`.
#' @param summary Include a summary of the result object.
#' @param output,warnings,error Include captured output, warnings and errors.
#' @param full_results Logical; if `TRUE`, bypass summarization and include the
#'   full result object. This may produce large responses and expose sensitive
#'   data.
#' @return By default a character string of plain text. When `plain = FALSE` a
#'   list representing the JSON response from the server is returned.
#' @export
exec_code <- function(code, port = 8080, plain = TRUE, summary = FALSE,
                      output = TRUE, warnings = TRUE, error = TRUE,
                      full_results = FALSE) {
  query <- list()
  if (plain) {
    query$format <- "text"
  } else {
    query$plain <- "false"
  }
  if (!summary && !full_results) query$summary <- "false"
  if (!output) query$output <- "false"
  if (!warnings) query$warnings <- "false"
  if (!error) query$error <- "false"
  if (full_results) query$full_results <- "true"
  qs <- if (length(query) > 0)
    paste0("?", paste(names(query), query, sep = "=", collapse = "&")) else ""
  url <- sprintf("http://127.0.0.1:%d/execute%s", as.integer(port), qs)
  res <- httr::POST(
    url,
    body = jsonlite::toJSON(list(command = code), auto_unbox = TRUE),
    encode = "json"
  )
  if (plain) {
    httr::content(res, as = "text", encoding = "UTF-8")
  } else {
    out <- jsonlite::fromJSON(httr::content(res, as = "text", encoding = "UTF-8"), simplifyVector = FALSE)
    if (!warnings) out$warning <- NULL
    out
  }
}

#' Query the status of a running replr server
#'
#' Retrieves basic status information from the server such as uptime and
#' version details.
#'
#' @param port Port number that the server is listening on.
#' @return A list parsed from the JSON status response.
#' @export
server_status <- function(port = 8080) {
  url <- sprintf("http://127.0.0.1:%d/status", as.integer(port))
  res <- httr::GET(url)
  jsonlite::fromJSON(httr::content(res, as = "text", encoding = "UTF-8"))
}

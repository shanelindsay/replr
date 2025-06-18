exec_code <- function(code, port = 8080, plain = FALSE, summary = TRUE,
                      output = TRUE, warnings = TRUE, error = TRUE) {
  query <- list()
  if (plain) query$format <- "text"
  if (!summary) query$summary <- "false"
  if (!output) query$output <- "false"
  if (!warnings) query$warnings <- "false"
  if (!error) query$error <- "false"
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

server_status <- function(port = 8080) {
  url <- sprintf("http://127.0.0.1:%d/status", as.integer(port))
  res <- httr::GET(url)
  jsonlite::fromJSON(httr::content(res, as = "text", encoding = "UTF-8"))
}

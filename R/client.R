exec_code <- function(code, port = 8080) {
  url <- sprintf("http://127.0.0.1:%d/execute", as.integer(port))
  res <- httr::POST(
    url,
    body = jsonlite::toJSON(list(command = code), auto_unbox = TRUE),
    encode = "json"
  )
  jsonlite::fromJSON(httr::content(res, as = "text", encoding = "UTF-8"), simplifyVector = FALSE)
}

server_status <- function(port = 8080) {
  url <- sprintf("http://127.0.0.1:%d/status", as.integer(port))
  res <- httr::GET(url)
  jsonlite::fromJSON(httr::content(res, as = "text", encoding = "UTF-8"))
}

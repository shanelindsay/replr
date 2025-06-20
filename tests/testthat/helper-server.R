wait_for_server <- function(port, timeout = 5) {
  url <- sprintf("http://127.0.0.1:%d/status", port)
  start <- Sys.time()
  repeat {
    res <- try(httr::GET(url), silent = TRUE)
    if (inherits(res, "response") && httr::status_code(res) == 200) {
      break(invisible(TRUE))
    }
    if (as.numeric(difftime(Sys.time(), start, units = "secs")) > timeout) {
      stop("Server did not respond in time", call. = FALSE)
    }
    Sys.sleep(0.1)
  }
}

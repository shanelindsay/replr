start_server <- function(port = 8080, host = "127.0.0.1", background = FALSE) {
  script <- system.file("scripts", "replr_server.R", package = "replr")
  cmd <- sprintf('Rscript "%s" --port %d --host %s %s',
                 script, as.integer(port), shQuote(host),
                 if (background) "--background" else "")
  system(cmd, wait = !background, invisible = TRUE)
}

stop_server <- function(port = 8080) {
  url <- sprintf("http://127.0.0.1:%d/shutdown", as.integer(port))
  tryCatch({
    httr::POST(url)
  }, error = function(e) message("Failed to shutdown server: ", e$message))
}

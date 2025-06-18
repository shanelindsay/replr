start_server <- function(port = 8080, background = FALSE) {
  script <- system.file("scripts", "r_json_server.R", package = "rjsonsrv")
  cmd <- sprintf('Rscript "%s" --port %d %s',
                 script, as.integer(port),
                 if (background) "--background" else "")
  system(cmd, wait = !background, invisible = TRUE)
}

stop_server <- function(port = 8080) {
  url <- sprintf("http://127.0.0.1:%d/shutdown", as.integer(port))
  tryCatch({
    httr::POST(url)
  }, error = function(e) message("Failed to shutdown server: ", e$message))
}

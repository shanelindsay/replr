#' Start the replr server
#'
#' Launches the HTTP server bundled with this package. The server is started
#' on the given host and port. When `background = TRUE` the server continues
#' running in a separate process.
#'
#' @param port Integer port number to listen on.
#' @param host Host interface to bind to.
#' @param background Logical; start the server in the background when `TRUE`.
#' @return Invisibly returns the command exit status.
#' @export
start_server <- function(port = 8080, host = "127.0.0.1", background = FALSE) {
  script <- system.file("scripts", "replr_server.R", package = "replr")
  cmd <- sprintf('Rscript "%s" --port %d --host %s %s',
                 script, as.integer(port), shQuote(host),
                 if (background) "--background" else "")
  system(cmd, wait = !background, invisible = TRUE)
  invisible(NULL)
}

#' Stop a running replr server
#'
#' Sends a shutdown request to the server started by `start_server()`.
#'
#' @param port Integer port number the server is listening on.
#' @return `NULL` invisibly. A message is printed if the request fails.
#' @export
stop_server <- function(port = 8080) {
  url <- sprintf("http://127.0.0.1:%d/shutdown", as.integer(port))
  tryCatch({
    httr::POST(url)
  }, error = function(e) message("Failed to shutdown server: ", e$message))
  invisible(NULL)
}

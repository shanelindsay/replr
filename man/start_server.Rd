% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/server.R
\name{start_server}
\alias{start_server}
\title{Start the replr server}
\usage{
start_server(port = 8080, host = "127.0.0.1", background = FALSE)
}
\arguments{
\item{port}{Integer port number to listen on.}

\item{host}{Host interface to bind to.}

\item{background}{Logical; start the server in the background when `TRUE`.}
}
\value{
Invisibly returns the command exit status.
}
\description{
Launches the HTTP server bundled with this package. The server is started
on the given host and port. When `background = TRUE` the server continues
running in a separate process.
}

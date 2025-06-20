#!/usr/bin/env Rscript

# R JSON HTTP Server
# This script creates a persistent HTTP server that communicates using JSON

# Parse command line arguments
args <- commandArgs(trailingOnly = TRUE)
run_mode <- "interactive"  # Default mode
command_to_run <- NULL
port <- 8080  # Default port
if (is.null(getOption("replr.preview_rows"))) {
  options(replr.preview_rows = 5)
}

# Process command line arguments
if (length(args) > 0) {
  i <- 1
  while (i <= length(args)) {
    if (args[i] == "--background" || args[i] == "-b") {
      run_mode <- "background"
      i <- i + 1
    } else if (args[i] == "--command" || args[i] == "-c") {
      if (i + 1 <= length(args)) {
        command_to_run <- paste(args[(i + 1):length(args)], collapse = " ")
        run_mode <- "command"
        break
      } else {
        stop("Missing command after --command|-c")
      }
      i <- length(args) + 1
    } else if (args[i] == "--port" || args[i] == "-p") {
      if (i + 1 <= length(args)) {
        port <- as.integer(args[i + 1])
        i <- i + 2
      } else {
        stop("Missing port number after --port|-p")
      }
    } else if (args[i] == "--help" || args[i] == "-h") {
      cat("Usage: Rscript replr_server.R [options]\n")
      cat("Options:\n")
      cat("  --background, -b     Run in background mode\n")
      cat("  --command, -c CMD    Execute a single command and exit\n")
      cat("  --port, -p PORT      Specify the port (default: 8080)\n")
      cat("  --help, -h           Show this help message\n")
      quit(save = "no", status = 0)
    } else {
      warning("Unknown argument: ", args[i])
      i <- i + 1
    }
  }
}

library(httpuv)
library(jsonlite)

base_dir <- Sys.getenv("REPLR_BASE_DIR", "r_comm")
img_dir <- file.path(base_dir, "images")
if (!dir.exists(img_dir)) {
  dir.create(img_dir, recursive = TRUE)
}

server <- NULL
last_call_time <- Sys.time()
heartbeat_file <- file.path(base_dir, "heartbeat.txt")
process_state_file <- file.path(base_dir, "r_process_state.txt")
process_pid_file <- file.path(base_dir, "r_process_pid.txt")
write(Sys.getpid(), process_pid_file)

server_state <- list(
  start_time = Sys.time(),
  last_call_time = Sys.time(),
  command_count = 0,
  last_command = NULL,
  last_result = NULL,
  last_error = NULL,
  r_version = R.version.string,
  pid = Sys.getpid()
)

write("running", process_state_file)
write(format(Sys.time(), "%Y-%m-%d %H:%M:%S"), heartbeat_file)

capture_output <- function(expr) {
  temp_output <- NULL
  temp_error <- NULL
  temp_plot <- NULL
  temp_warning <- character()
  temp_result <- NULL

  output_conn <- textConnection("temp_output", "w", local = TRUE)
  error_conn <- textConnection("temp_error", "w", local = TRUE)
  old_output <- getOption("warning.expression")
  old_sink_output <- getOption("sink.output")
  sink(output_conn, type = "output", append = TRUE)
  plot_index <- 1
  plot_files <- character(0)

  pdf(NULL)
  dev.control(displaylist = "enable")
  base_plot <- recordPlot()

  withCallingHandlers(
    tryCatch({
      temp_result <- eval(parse(text = expr), envir = .GlobalEnv)
      if (!is.null(temp_result)) {
        temp_output <- c(temp_output, capture.output(temp_result))
      }
      rec_plot <- recordPlot()
      if (dev.cur() > 1 && inherits(rec_plot, "recordedplot") &&
          !identical(rec_plot[[2]], base_plot[[2]])) {
        plot_file <- file.path(img_dir, paste0("plot_", format(Sys.time(), "%Y%m%d_%H%M%S_"), plot_index, ".png"))
        png(file = plot_file, width = 800, height = 600)
        replayPlot(rec_plot)
        dev.off()
        plot_files <- c(plot_files, plot_file)
        plot_index <- plot_index + 1
      }
    }, error = function(e) {
      sink(error_conn, type = "message")
      message("Error: ", conditionMessage(e))
      sink(NULL, type = "message")
    }),
    warning = function(w) {
      temp_warning <- c(temp_warning, conditionMessage(w))
      invokeRestart("muffleWarning")
    }
  )

  sink(NULL)
  close(output_conn)
  close(error_conn)
  dev.off()

  write(format(Sys.time(), "%Y-%m-%d %H:%M:%S"), heartbeat_file)

  list(
    result = temp_result,
    output = paste(temp_output, collapse = "\n"),
    error = paste(temp_error, collapse = "\n"),
    warning = temp_warning,
    plots = plot_files
  )
}

parse_query_string <- function(x) {
  if (is.null(x) || nchar(x) == 0) return(list())
  x <- sub('^[?]', '', x)
  parts <- strsplit(x, "&", fixed = TRUE)[[1]]
  kv <- strsplit(parts, "=", fixed = TRUE)
  out <- setNames(lapply(kv, function(p) if (length(p) > 1) utils::URLdecode(p[2]) else ""), sapply(kv, `[`, 1))
  out
}

process_request <- function(req) {
  server_state$last_call_time <- Sys.time()
  write(format(server_state$last_call_time, "%Y-%m-%d %H:%M:%S"), heartbeat_file)

  qs <- parse_query_string(req$QUERY_STRING)
  plain_text <- if (is.null(qs$plain) && is.null(qs$format)) {
    TRUE
  } else {
    isTRUE(as.logical(qs$plain)) || identical(qs$format, "text")
  }
  full_results <- if (!is.null(qs$full_results)) as.logical(qs$full_results) else FALSE
  summary_enabled <- if (!is.null(qs$summary)) {
    as.logical(qs$summary)
  } else if (full_results) {
    FALSE
  } else {
    TRUE
  }
  include_output <- if (!is.null(qs$output)) as.logical(qs$output) else getOption("rjson.output", TRUE)
  include_warnings <- if (!is.null(qs$warnings)) as.logical(qs$warnings) else getOption("rjson.warnings", TRUE)
  include_error <- if (!is.null(qs$error)) as.logical(qs$error) else getOption("rjson.error", TRUE)

  if (req$PATH_INFO == "/status") {
    list(
      status = 200L,
      headers = list('Content-Type' = 'application/json'),
      body = toJSON(list(
        status = "running",
        uptime = as.numeric(difftime(Sys.time(), server_state$start_time, units = "secs")),
        pid = Sys.getpid(),
        r_version = R.version.string
      ), auto_unbox = TRUE)
    )
  } else if (req$PATH_INFO == "/state") {
    vars <- ls(envir = .GlobalEnv)
    list(
      status = 200L,
      headers = list('Content-Type' = 'application/json'),
      body = toJSON(list(
        status = "running",
        uptime = as.numeric(difftime(Sys.time(), server_state$start_time, units = "secs")),
        last_call_time = format(server_state$last_call_time, "%Y-%m-%d %H:%M:%S"),
        command_count = server_state$command_count,
        variables = vars,
        last_command = server_state$last_command,
        r_version = R.version.string,
        pid = Sys.getpid()
      ), auto_unbox = TRUE)
    )
  } else if (req$PATH_INFO == "/shutdown") {
    write("stopped", process_state_file)
    cat("Shutting down R server\n")
    later::later(function() {
      if (!is.null(server)) {
        server$stop()
      }
      quit(save = "no")
    }, 0.5)
    list(
      status = 200L,
      headers = list('Content-Type' = 'application/json'),
      body = toJSON(list(status = "shutting_down"), auto_unbox = TRUE)
    )
  } else if (req$PATH_INFO == "/execute") {
    if (req$REQUEST_METHOD == "POST") {
      request_body <- rawToChar(req$rook.input$read())
      request_data <- fromJSON(request_body)
      if (!is.null(request_data$command)) {
        cmd <- request_data$command
        server_state$last_command <- cmd
        server_state$command_count <- server_state$command_count + 1
        cat("Executing: ", cmd, "\n")
        result <- capture_output(cmd)
        if (!is.null(result$result) && summary_enabled) {
          if (is.data.frame(result$result)) {
            result$result_summary <- list(
              type = "data.frame",
              dim = dim(result$result),
              columns = names(result$result),
              preview = head(result$result, getOption("replr.preview_rows", 5))
            )
          }
          else if (inherits(result$result, "lm") || inherits(result$result, "glm")) {
            model_summary <- summary(result$result)
            result$result_summary <- list(
              type = class(result$result)[1],
              formula = as.character(result$result$call$formula),
              r_squared = if(inherits(result$result, "lm")) model_summary$r.squared else NULL,
              aic = if(inherits(result$result, "glm")) model_summary$aic else NULL,
              coefficients = model_summary$coefficients
            )
          }
          else if (inherits(result$result, "table")) {
            result$result_summary <- list(
              type = "table",
              dim = dim(result$result),
              preview = if(all(dim(result$result) <= c(10, 10))) unclass(result$result) else "Table too large to preview"
            )
          }
          else if (is.matrix(result$result)) {
            result$result_summary <- list(
              type = "matrix",
              dim = dim(result$result),
              preview = if(all(dim(result$result) <= c(10, 10))) unclass(result$result) else "Matrix too large to preview"
            )
          }
          else if (is.vector(result$result) && length(result$result) > 100) {
            result$result_summary <- list(
              type = typeof(result$result),
              length = length(result$result),
              preview = head(result$result, getOption("replr.preview_rows", 5))
            )
          }
          else {
            result$result_summary <- list(
              type = typeof(result$result)
            )
          }
        }
        server_state$last_result <- result
        response <- list()
        if (include_output) response$output <- result$output
        if (include_error) response$error <- result$error
        if (include_warnings) response$warning <- result$warning
        response$plots <- result$plots
        if (full_results) response$result <- result$result
        if (summary_enabled) response$result_summary <- result$result_summary
        if (nchar(result$error) > 0) {
          server_state$last_error <- result$error
        }
        if (plain_text) {
          text_body <- character()
          if (include_output && nchar(result$output) > 0) text_body <- c(text_body, result$output)
          if (include_warnings && length(result$warning) > 0) text_body <- c(text_body, paste("Warnings:", paste(result$warning, collapse = "\n")))
          if (include_error && nchar(result$error) > 0) text_body <- c(text_body, paste("Error:", result$error))
          if (!is.null(result$result)) text_body <- c(text_body, paste(capture.output(result$result), collapse = "\n"))
          if (summary_enabled && !is.null(result$result_summary)) text_body <- c(text_body, paste(capture.output(str(result$result_summary)), collapse = "\n"))
          list(
            status = 200L,
            headers = list('Content-Type' = 'text/plain'),
            body = paste(text_body, collapse = "\n")
          )
        } else {
          list(
            status = 200L,
            headers = list('Content-Type' = 'application/json'),
            body = toJSON(response, auto_unbox = TRUE, null = "null")
          )
        }
      } else {
        list(
          status = 400L,
          headers = list('Content-Type' = 'application/json'),
          body = toJSON(list(status = "error", message = "Missing 'command' parameter"), auto_unbox = TRUE)
        )
      }
    } else {
      list(
        status = 405L,
        headers = list('Content-Type' = 'application/json'),
        body = toJSON(list(status = "error", message = "Method not allowed"), auto_unbox = TRUE)
      )
    }
  } else {
    list(
      status = 404L,
      headers = list('Content-Type' = 'application/json'),
      body = toJSON(list(status = "error", message = "Endpoint not found"), auto_unbox = TRUE)
    )
  }
}

app <- list(
  call = function(req) {
    process_request(req)
  },
  onWSOpen = function(ws) {
    # WebSocket support could be added here
  }
)

if (run_mode == "interactive" || run_mode == "background") {
  cat("Starting R JSON server on port", port, "\n")
  cat("Server PID:", Sys.getpid(), "\n")
  server <<- startServer("127.0.0.1", port, app)
  if (exists("tools::.signal_interruptible")) {
    tools::.signal_interruptible(2, function(sig) {
      cat("Received interrupt signal. Shutting down...\n")
      write("stopped", process_state_file)
      if (!is.null(server)) {
        server$stop()
      }
      quit(save = "no")
    })
  }
  if (run_mode == "interactive") {
    cat("Server is running. Press Ctrl+C to stop.\n")
  } else {
    cat("Server is running in background mode.\n")
    cat("To stop the server, send a request to /shutdown or kill process", Sys.getpid(), "\n")
  }
  while (TRUE) {
    httpuv::service()
    Sys.sleep(0.001)
    if (difftime(Sys.time(), last_call_time, units = "secs") >= 10) {
      write(format(Sys.time(), "%Y-%m-%d %H:%M:%S"), heartbeat_file)
      last_call_time <- Sys.time()
    }
  }
} else if (run_mode == "command") {
  cat("Executing command:", command_to_run, "\n")
  result <- capture_output(command_to_run)
  cat("\n=== Output ===\n")
  cat(result$output)
  if (nchar(result$error) > 0) {
    cat("\n=== Error ===\n")
    cat(result$error)
  }
  if (length(result$warning) > 0) {
    cat("\n=== Warnings ===\n")
    cat(paste(result$warning, collapse = "\n"))
  }
  if (length(result$plots) > 0) {
    cat("\n=== Plots saved to ===\n")
    cat(paste(result$plots, collapse = "\n"))
  }
  write("stopped", process_state_file)
  quit(save = "no")
}

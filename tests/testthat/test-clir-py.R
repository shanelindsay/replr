test_that("Python CLI can start, exec code, and stop", {
  skip_on_cran()
  script <- normalizePath(file.path("..", "..", "tools", "clir.py"))
  label <- "pytest"
  port <- 8150
  # run from the scripts directory so clir.py finds replr_server.R
  workdir <- normalizePath(file.path("..", "..", "inst", "scripts"))
  # start the server
  start_status <- withr::with_dir(
    workdir,
    system2("python3", c(script, "start", label, as.character(port)))
  )
  expect_equal(start_status, 0)
  on.exit(withr::with_dir(workdir,
                          system2("python3", c(script, "stop", label))),
          add = TRUE)
  Sys.sleep(1)
  # execute code requesting JSON output
  out_exec <- processx::run(
    "python3",
    c(script, "exec", label, "--json", "-e", "1+1"),
    wd = workdir,
    error_on_status = FALSE
  )
  expect_equal(out_exec$status, 0)
  json_text <- sub("^[^{]*", "", out_exec$stdout)
  result <- jsonlite::fromJSON(json_text)
  expect_equal(result$result_summary$type, "double")
})

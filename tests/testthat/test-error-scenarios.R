skip_on_cran()

test_that("server responds with error to malformed JSON", {
  ps <- processx::process$new(
    "Rscript",
    c(system.file("scripts", "replr_server.R", package = "replr"),
      "--port", 8133, "--host", "127.0.0.1", "--background")
  )
  on.exit(ps$kill())
  wait_for_server(8133)
  res <- httr::POST(
    "http://127.0.0.1:8133/execute",
    body = '{"bad":}',
    encode = "raw"
  )
  expect_equal(httr::status_code(res), 500)
  st <- replr::server_status(8133)
  expect_equal(st$status, "running")
})

test_that("large outputs are summarized correctly", {
  ps <- processx::process$new(
    "Rscript",
    c(system.file("scripts", "replr_server.R", package = "replr"),
      "--port", 8134, "--host", "127.0.0.1", "--background")
  )
  on.exit(ps$kill())
  wait_for_server(8134)
  res <- replr::exec_code("1:10000", port = 8134, plain = FALSE, summary = TRUE)
  expect_equal(res$result_summary$type, "integer")
  expect_equal(res$result_summary$length, 10000)
  expect_equal(as.integer(res$result_summary$preview), 1:5)
})

test_that("exec_code returns rjson_response class", {
  skip_on_cran()
  ps <- processx::process$new(
    "Rscript",
    c(system.file("scripts", "replr_server.R", package = "replr"),
      "--port", 8155, "--host", "127.0.0.1", "--background")
  )
  on.exit(ps$kill())
  wait_for_server(8155)
  res <- replr::exec_code("1+1", port = 8155, plain = FALSE, summary = TRUE)
  expect_true("rjson_response" %in% class(res))
})

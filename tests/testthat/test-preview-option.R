test_that("default preview_rows is 5", {
  skip_on_cran()
  ps <- processx::process$new("Rscript", c(system.file("scripts", "replr_server.R", package="replr"), "--port", 8130, "--host", "127.0.0.1", "--background"))
  on.exit(ps$kill())
  wait_for_server(8130)

  res <- replr::exec_code("data.frame(a=1:10)", port=8130, plain = FALSE, summary = TRUE)
  expect_equal(length(res$result_summary$preview), 5)
})

test_that("preview_rows option can be changed", {
  skip_on_cran()
  ps <- processx::process$new("Rscript", c(system.file("scripts", "replr_server.R", package="replr"), "--port", 8131, "--host", "127.0.0.1", "--background"))
  on.exit(ps$kill())
  wait_for_server(8131)
  replr::exec_code("options(replr.preview_rows=3)", port=8131, plain = FALSE)
  res <- replr::exec_code("data.frame(a=1:10)", port=8131, plain = FALSE, summary = TRUE)

  expect_equal(length(res$result_summary$preview), 3)
})

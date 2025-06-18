test_that("round-trip code returns expected result", {
  skip_on_cran()
  ps <- processx::process$new("Rscript", c(system.file("scripts", "replr_server.R", package="replr"), "--port", 8123, "--background"))
  on.exit(ps$kill())
  Sys.sleep(1)
  res <- replr::exec_code("1+1", port=8123)
  expect_equal(res$result_summary$type, "double")
})

test_that("plain text mode works", {
  skip_on_cran()
  ps <- processx::process$new("Rscript", c(system.file("scripts", "replr_server.R", package="replr"), "--port", 8124, "--background"))
  on.exit(ps$kill())
  Sys.sleep(1)
  res <- replr::exec_code("1+1", port=8124, plain = TRUE)
  expect_match(res, "2")
})

test_that("warnings can be suppressed", {
  skip_on_cran()
  ps <- processx::process$new("Rscript", c(system.file("scripts", "replr_server.R", package="replr"), "--port", 8125, "--background"))
  on.exit(ps$kill())
  Sys.sleep(1)
  res <- replr::exec_code("warning('a'); 1", port=8125, warnings = FALSE)
  expect_false("warning" %in% names(res))
})

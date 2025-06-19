test_that("round-trip code returns expected result", {
  skip_on_cran()
  ps <- processx::process$new("Rscript", c(system.file("scripts", "replr_server.R", package="replr"), "--port", 8123, "--background"))
  on.exit(ps$kill())
  Sys.sleep(1)
  res <- replr::exec_code("1+1", port=8123, plain = FALSE, summary = TRUE)
  expect_equal(res$result_summary$type, "double")
})

test_that("plain text mode works", {
  skip_on_cran()
  ps <- processx::process$new(
    "Rscript",
    c(system.file("scripts", "replr_server.R", package = "replr"),
      "--port", 8124, "--background")
  )
  on.exit(ps$kill())
  Sys.sleep(1)
  res <- replr::exec_code("1+1", port = 8124, plain = TRUE)
  expect_type(res, "character")
  expect_match(res, "\\[1\\] 2")
})

test_that("explicit plain = FALSE returns JSON", {
  skip_on_cran()
  ps <- processx::process$new(
    "Rscript",
    c(system.file("scripts", "replr_server.R", package = "replr"),
      "--port", 8128, "--background")
  )
  on.exit(ps$kill())
  Sys.sleep(1)
  res <- replr::exec_code("1+1", port = 8128, plain = FALSE, summary = TRUE)
  expect_equal(res$result_summary$type, "double")
})

test_that("warnings can be suppressed", {
  skip_on_cran()
  ps <- processx::process$new("Rscript", c(system.file("scripts", "replr_server.R", package="replr"), "--port", 8125, "--background"))
  on.exit(ps$kill())
  Sys.sleep(1)
  res <- replr::exec_code("warning('a'); 1", port=8125, warnings = FALSE,
                           plain = FALSE, summary = TRUE)
  expect_false("warning" %in% names(res))
})

test_that("errors are captured correctly", {
  skip_on_cran()
  ps <- processx::process$new("Rscript", c(system.file("scripts", "replr_server.R", package="replr"), "--port", 8126, "--background"))
  on.exit(ps$kill())
  Sys.sleep(1)
  res <- replr::exec_code("log('foo')", port=8126, plain = FALSE, summary = TRUE)
  expect_equal(res$output, "")
  expect_match(res$error, "non-numeric")
})

test_that("full results are returned when requested", {
  skip_on_cran()
  ps <- processx::process$new("Rscript", c(system.file("scripts", "replr_server.R", package="replr"), "--port", 8127, "--background"))
  on.exit(ps$kill())
  Sys.sleep(1)
  res <- replr::exec_code("list(a = 1:3)", port = 8127, full_results = TRUE,
                          plain = FALSE)
  expect_equal(unlist(res$result$a), 1:3)
  expect_false("result_summary" %in% names(res))
})

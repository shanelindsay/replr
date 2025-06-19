test_that("CLI auto-starts server", {
  skip_on_cran()
  script <- file.path("..", "..", "tools", "clir.sh")
  out <- processx::run("bash", c(script, "exec", "autotest", "-e", "1+1", "--json"), error_on_status = FALSE)
  expect_equal(out$status, 0)
  result <- jsonlite::fromJSON(out$stdout)
  expect_equal(result$result_summary$type, "double")
  processx::run("bash", c(script, "stop", "autotest"))
})

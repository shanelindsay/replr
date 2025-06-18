test_that("round-trip code returns expected result", {
  skip_on_cran()
  ps <- processx::process$new("Rscript", c(system.file("scripts", "r_json_server.R", package="rjsonsrv"), "--port", 8123, "--background"))
  on.exit(ps$kill())
  Sys.sleep(1)
  res <- rjsonsrv::exec_code("1+1", port=8123)
  expect_equal(res$result_summary$type, "double")
})

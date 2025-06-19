test_that("--command works with quoted expressions", {
  skip_on_cran()
  out <- processx::run(
    "Rscript",
    c(system.file("scripts", "replr_server.R", package = "replr"),
      "--command", "sum(1:5)"),
    echo = FALSE,
    error_on_status = FALSE
  )
  expect_equal(out$status, 0)
})

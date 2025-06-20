skip_on_cran()

library(replr)

# Start a background server
ps <- processx::process$new(
  "Rscript",
  c(system.file("scripts", "replr_server.R", package = "replr"),
    "--port", 8155, "--host", "127.0.0.1", "--background")
)
on.exit(ps$kill())
wait_for_server(8155)

exec_code("x <- 42", port = 8155)
info <- server_state(8155)

expect_equal(info$status, "running")
expect_true("x" %in% info$variables)
expect_gte(info$command_count, 1)

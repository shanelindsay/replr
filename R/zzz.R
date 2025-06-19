.onLoad <- function(libname, pkgname) {
  op <- options()
  op.replr <- list(
    replr.preview_rows = 5
  )
  toset <- !(names(op.replr) %in% names(op))
  if (any(toset)) options(op.replr[toset])
  invisible()
}

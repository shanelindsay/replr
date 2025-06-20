#!/usr/bin/env Rscript

# Build the package and run R CMD check.

# Determine repository root relative to this script
args <- commandArgs(trailingOnly = FALSE)
script_path <- sub("^--file=", "", args[grep("^--file=", args)])
if (length(script_path) == 0) {
  script_dir <- getwd()
} else {
  script_dir <- dirname(normalizePath(script_path))
}
repo_root <- normalizePath(file.path(script_dir, ".."))
setwd(repo_root)

# Read package metadata
desc <- read.dcf("DESCRIPTION")
package_name <- desc[1, "Package"]
package_version <- desc[1, "Version"]

# Build
build_cmd <- c("CMD", "build", repo_root)
status <- system2("R", build_cmd)
if (status != 0) {
  stop("R CMD build failed")
}

# Path to built tarball
tarball <- sprintf("%s_%s.tar.gz", package_name, package_version)

# Check
check_cmd <- c("CMD", "check", tarball)
status <- system2("R", check_cmd)
if (status != 0) {
  stop("R CMD check failed")
}

cat("Build and check completed successfully.\n")

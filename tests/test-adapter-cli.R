#!/usr/bin/env Rscript

script_arg <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
if (length(script_arg) != 1L) {
  stop("Run this check with Rscript tests/test-adapter-cli.R")
}
repo_root <- normalizePath(file.path(dirname(sub("^--file=", "", script_arg)), ".."))

fixture <- tempfile("volcano-adapter-")
dir.create(fixture, recursive = TRUE)
on.exit(unlink(fixture, recursive = TRUE), add = TRUE)

input_path <- file.path(fixture, "DEG_Analysis.csv")
deg_table <- data.frame(
  GeneName = paste0("Gene", seq_len(24L)),
  `B-A_logFC` = seq(-2.4, 2.2, length.out = 24L),
  `B-A_pval` = c(0.0001, 0.001, 0.01, seq(0.06, 0.99, length.out = 21L)),
  check.names = FALSE
)
write.csv(deg_table, input_path, row.names = FALSE)

run_adapter <- function(resolution_flag) {
  output_dir <- file.path(fixture, sub("^--", "", resolution_flag))
  args <- c(
    file.path(repo_root, "code/main.R"),
    "--deg_table", input_path,
    "--output_dir", output_dir,
    "--column_with_feature_id", "GeneName",
    "--significance_column", "B-A_pval",
    "--log2_fold_change_column", "B-A_logFC",
    "--image_width", "600",
    "--image_height", "600",
    resolution_flag, "100",
    "--number_of_features_to_label", "3"
  )
  output <- system2("Rscript", args, stdout = TRUE, stderr = TRUE)
  status <- attr(output, "status")
  if (!is.null(status) && status != 0L) {
    stop(paste(output, collapse = "\n"))
  }
  stopifnot(
    file.exists(file.path(output_dir, "volcano_plot.png")),
    file.exists(file.path(output_dir, "volcano_plot_data.csv")),
    nrow(read.csv(file.path(output_dir, "volcano_plot_data.csv"))) == nrow(deg_table)
  )
  output
}

canonical_output <- run_adapter("--resolution_dpi")
stopifnot(!any(grepl("is deprecated", canonical_output, fixed = TRUE)))

compatibility_output <- run_adapter("--resolution_dpi_")
stopifnot(any(grepl("is deprecated", compatibility_output, fixed = TRUE)))

message("Representative adapter execution and resolution compatibility checks passed")

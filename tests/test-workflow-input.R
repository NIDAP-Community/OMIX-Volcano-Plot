#!/usr/bin/env Rscript

script_arg <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
if (length(script_arg) != 1L) {
  stop("Run this check with Rscript tests/test-workflow-input.R")
}
repo_root <- normalizePath(file.path(dirname(sub("^--file=", "", script_arg)), ".."))
source(file.path(repo_root, "code", "functions", "workflow_input.R"))

expect_error <- function(expression, pattern) {
  error <- tryCatch({ force(expression); NULL }, error = identity)
  stopifnot(inherits(error, "error"), grepl(pattern, conditionMessage(error), fixed = TRUE))
}

fixture <- tempfile("volcano-workflow-")
workflow_dir <- file.path(fixture, "workflow-id")
dir.create(workflow_dir, recursive = TRUE)
on.exit(unlink(fixture, recursive = TRUE), add = TRUE)

deg_table <- data.frame(
  GeneName = c("GeneA", "GeneB"),
  `B-A_logFC` = c(2, -2),
  `B-A_pval` = c(0.001, 0.002),
  `B-A_adjpval` = c(0.01, 0.02),
  `C-A_logFC` = c(3, -3),
  `C-A_pval` = c(0.003, 0.004),
  `C-A_adjpval` = c(0.03, 0.04),
  check.names = FALSE
)
deg_path <- file.path(workflow_dir, "DEG_Analysis.csv")
write.csv(deg_table, deg_path, row.names = FALSE)
write.csv(data.frame(Package = "example"), file.path(workflow_dir, "r-packages.csv"), row.names = FALSE)

stopifnot(identical(normalizePath(find_workflow_csv(fixture)), normalizePath(deg_path)))
nominal <- resolve_workflow_volcano_columns(deg_table, "nominal")
adjusted <- resolve_workflow_volcano_columns(deg_table, "adjusted")
stopifnot(
  identical(nominal$column_with_feature_id, "GeneName"),
  identical(nominal$significance_columns, c("B-A_pval", "C-A_pval")),
  identical(nominal$log2_fold_change_columns, c("B-A_logFC", "C-A_logFC")),
  identical(adjusted$significance_columns, c("B-A_adjpval", "C-A_adjpval")),
  identical(adjusted$log2_fold_change_columns, c("B-A_logFC", "C-A_logFC"))
)

gene_symbols_table <- deg_table
names(gene_symbols_table)[names(gene_symbols_table) == "GeneName"] <- "Gene Symbols"
stopifnot(identical(
  resolve_workflow_volcano_columns(gene_symbols_table, "nominal")$column_with_feature_id,
  "Gene Symbols"
))

second_deg <- file.path(workflow_dir, "another_DEG_table.csv")
write.csv(data.frame(x = 1), second_deg, row.names = FALSE)
expect_error(find_workflow_csv(fixture), "Multiple workflow DEG CSV files")

message("Volcano workflow-input checks passed")

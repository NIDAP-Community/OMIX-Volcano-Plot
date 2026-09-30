#!/usr/bin/env Rscript

# OMIX Volcano - CLI-first volcano plot generator
# Accepts parameters via command-line arguments from App Panel

suppressPackageStartupMessages({
  library(optparse)
  library(dplyr)
  library(tidyr)
  library(ggplot2)
  library(ggrepel)
  library(stringr)
})

get_script_dir <- function() {
  file_arg <- commandArgs(FALSE)[grepl("^--file=", commandArgs(FALSE))]
  if (length(file_arg) == 0) {
    return(getwd())
  }
  dirname(normalizePath(sub("^--file=", "", file_arg[1]), mustWork = TRUE))
}

runtime_root <- normalizePath(file.path(get_script_dir(), ".."), mustWork = TRUE)

# Canonical interface controls plus one hidden deprecated adapter alias.
option_list <- list(
  make_option("--deg_table", type = "character", default = NULL),
  make_option("--output_dir", type = "character", default = "results"),
  make_option("--pvalue_type", type = "character", default = "nominal"),
  make_option("--column_with_feature_id", type = "character", default = NULL),
  make_option("--significance_column", type = "character", default = NULL),
  make_option("--log2_fold_change_column", type = "character", default = NULL),
  make_option("--p_value_threshold", type = "double", default = 0.05),
  make_option("--log2_fold_change_threshold", type = "double", default = 1.0),
  make_option("--choose_feature_to_label_by", type = "character", default = "p-value"),
  make_option("--number_of_features_to_label", type = "integer", default = 30),
  make_option("--label_only_my_feature_list", type = "character", default = "false"),
  make_option("--my_feature_list", type = "character", default = ""),
  make_option("--top_genes_labeled_only_if_passing_thresholds", type = "character", default = "true"),
  make_option("--label_size", type = "double", default = 4),
  make_option("--label_box_padding", type = "double", default = 1),
  make_option("--label_force", type = "double", default = 1),
  make_option("--label_max_overlaps", type = "double", default = Inf),
  make_option("--use_custom_axis_label", type = "character", default = "false"),
  make_option("--custom_significance_label", type = "character", default = "p-value"),
  make_option("--custom_log_fold_change_label", type = "character", default = "log2FC"),
  make_option("--plot_title", type = "character", default = "Volcano Plot"),
  make_option("--plot_subtitle", type = "character", default = ""),
  make_option("--y_limit", type = "double", default = 0),
  make_option("--use_auto_axis_capping", type = "character", default = "true"),
  make_option("--auto_axis_capping_quantile", type = "double", default = 0.9999),
  make_option("--auto_axis_capping_symmetric_x", type = "character", default = "true"),
  make_option("--custom_x_axis_limits", type = "character", default = ""),
  make_option("--x_limit_padding", type = "double", default = 0),
  make_option("--y_limit_padding", type = "double", default = 0),
  make_option("--plot_title_size", type = "double", default = 16),
  make_option("--axis_title_size", type = "double", default = 14),
  make_option("--axis_text_size", type = "double", default = 12),
  make_option("--point_size", type = "double", default = 2),
  make_option("--image_width", type = "integer", default = 3000),
  make_option("--image_height", type = "integer", default = 3000),
  make_option("--resolution_dpi", type = "integer", default = 300),
  make_option("--color_not_significant", type = "character", default = "gray"),
  make_option("--color_fold_change_only", type = "character", default = "orange"),
  make_option("--color_significant_only", type = "character", default = "green4"),
  make_option("--color_significant_and_fold_change", type = "character", default = "red3"),
  make_option(
    "--resolution_dpi_",
    type = "integer",
    default = NULL,
    help = "Deprecated Code Ocean compatibility alias; use --resolution_dpi"
  )
)

parser <- OptionParser(
  usage = "Usage: %prog [options]\nDEG table can be uploaded via --deg_table or discovered from attached data.",
  option_list = option_list,
  description = "Generate enhanced volcano plots from differential expression analysis"
)

# Code Ocean passes --param "" for blank uploads. Remove those pairs before
# optparse sees them, because an empty file value is not a usable path.
args <- commandArgs(trailingOnly = TRUE)
filtered_args <- character()
index <- 1L
while (index <= length(args)) {
  if (args[[index]] == "") {
    index <- index + 1L
  } else if (index < length(args) && startsWith(args[[index]], "--") && args[[index + 1L]] == "") {
    index <- index + 2L
  } else {
    filtered_args <- c(filtered_args, args[[index]])
    index <- index + 1L
  }
}
opt <- parse_args(parser, args = filtered_args)

as_logical <- function(value, option_name) {
  normalized <- tolower(trimws(value))
  if (!normalized %in% c("true", "false")) {
    stop("ERROR: `--", option_name, "` must be true or false")
  }
  identical(normalized, "true")
}

as_columns <- function(value) {
  if (is.null(value) || !nzchar(trimws(value))) return(NULL)
  trimws(strsplit(value, ",", fixed = TRUE)[[1L]])
}

opt$label_only_my_feature_list <- as_logical(
  opt$label_only_my_feature_list,
  "label_only_my_feature_list"
)
opt$top_genes_labeled_only_if_passing_thresholds <- as_logical(
  opt$top_genes_labeled_only_if_passing_thresholds,
  "top_genes_labeled_only_if_passing_thresholds"
)
opt$use_custom_axis_label <- as_logical(opt$use_custom_axis_label, "use_custom_axis_label")
opt$use_auto_axis_capping <- as_logical(opt$use_auto_axis_capping, "use_auto_axis_capping")
opt$auto_axis_capping_symmetric_x <- as_logical(
  opt$auto_axis_capping_symmetric_x,
  "auto_axis_capping_symmetric_x"
)

resolved_resolution_dpi <- opt$resolution_dpi
if (!is.null(opt$resolution_dpi_)) {
  warning("`--resolution_dpi_` is deprecated; use `--resolution_dpi`.", call. = FALSE)
  resolved_resolution_dpi <- opt$resolution_dpi_
}

# Find and read DEG table: uploaded file > workflow CSV > data asset > example data.
# Supports both RDS and CSV/TSV/TXT files

deg_data <- NULL
deg_table_path <- NULL

load_deg_file <- function(path) {
  file_ext <- tolower(tools::file_ext(path))
  if (file_ext == "rds") {
    data <- readRDS(path)
    if (is.list(data) && !is.data.frame(data)) {
      df_elements <- vapply(data, is.data.frame, logical(1))
      if (!any(df_elements)) {
        stop("ERROR: RDS file does not contain a data frame")
      }
      data <- data[[which(df_elements)[1L]]]
      message("Extracted data frame from list")
    }
    return(data)
  }
  if (file_ext == "csv") {
    return(read.csv(path, stringsAsFactors = FALSE, check.names = FALSE))
  }
  read.delim(path, stringsAsFactors = FALSE, check.names = FALSE)
}

source(file.path(runtime_root, "code", "adapter", "workflow_input.R"))

# Priority 1: use the explicitly selected canonical input.
if (!is.null(opt$deg_table) && nzchar(opt$deg_table)) {
  if (!file.exists(opt$deg_table)) {
    stop("ERROR: DEG table was not found: ", opt$deg_table)
  }
  deg_table_path <- normalizePath(opt$deg_table, mustWork = TRUE)
  message(sprintf("Loading explicitly selected DEG table: %s", deg_table_path))
  deg_data <- load_deg_file(deg_table_path)
}

# Priority 2: use a durable wide DEG CSV from an upstream Code Ocean workflow.
if (is.null(deg_data)) {
  workflow_csv_path <- find_workflow_csv()
  if (!is.null(workflow_csv_path)) {
    deg_table_path <- workflow_csv_path
    deg_data <- load_deg_file(deg_table_path)
    workflow_columns <- resolve_workflow_volcano_columns(deg_data, opt$pvalue_type)
    if (is.null(opt$column_with_feature_id) || !nzchar(opt$column_with_feature_id)) {
      opt$column_with_feature_id <- workflow_columns$column_with_feature_id
    }
    if (is.null(opt$significance_column) || !nzchar(opt$significance_column)) {
      opt$significance_column <- paste(workflow_columns$significance_columns, collapse = ",")
    }
    if (is.null(opt$log2_fold_change_column) || !nzchar(opt$log2_fold_change_column)) {
      opt$log2_fold_change_column <- paste(workflow_columns$log2_fold_change_columns, collapse = ",")
    }
    message(
      "Loading workflow DEG table: ", deg_table_path,
      "\n  Feature=", opt$column_with_feature_id,
      "; p-value=", opt$significance_column,
      "; log2FC=", opt$log2_fold_change_column
    )
  }
}

# Priority 3: use exactly one supported file from the attached DEG data asset.
if (is.null(deg_data)) {
  attached_path <- find_attached_deg_table()
  if (!is.null(attached_path)) {
    deg_table_path <- attached_path
    message(sprintf("Loading attached DEG table: %s", deg_table_path))
    deg_data <- load_deg_file(deg_table_path)
  }
}

# Priority 4: Fallback to example data
if (is.null(deg_data)) {
  example_path <- file.path(runtime_root, "data", "example_inputs", "deg_table.csv")
  if (file.exists(example_path)) {
    message("Note: No uploaded file or data asset found, using example data from data/example_inputs/deg_table.csv")
    deg_data <- read.csv(example_path, stringsAsFactors = FALSE, check.names = FALSE)
  } else {
    stop("ERROR: No DEG table file provided. Please upload a file or attach a DEG table data asset.")
  }
}

# Verify we have a data frame
if (!is.data.frame(deg_data)) {
  stop("ERROR: Loaded data is not a data frame")
}

message(sprintf("Loaded DEG table: %d rows x %d columns", nrow(deg_data), ncol(deg_data)))
message(sprintf("Available columns: %s\n", paste(colnames(deg_data), collapse=", ")))

deg_table <- deg_data

# Code Ocean owns /results. Outside Code Ocean, retain the canonical
# --output_dir default and explicit-path behavior.
results_dir <- opt$output_dir
if (dir.exists("/results") && identical(opt$output_dir, "results")) {
  results_dir <- "/results"
}
dir.create(results_dir, recursive = TRUE, showWarnings = FALSE)

# Source volcano plot function
source(file.path(runtime_root, "code", "functions", "Volcano_Plot_Enhanced.R"))

# Call volcano plot function
result <- volcano_plot_enhanced(
  deg_table = deg_table,
  pvalue_type = opt$pvalue_type,
  column_with_feature_id = opt$column_with_feature_id,
  significance_column = as_columns(opt$significance_column),
  log2_fold_change_column = as_columns(opt$log2_fold_change_column),
  p_value_threshold = opt$p_value_threshold,
  log2_fold_change_threshold = opt$log2_fold_change_threshold,
  choose_feature_to_label_by = opt$choose_feature_to_label_by,
  number_of_features_to_label = opt$number_of_features_to_label,
  label_only_my_feature_list = opt$label_only_my_feature_list,
  use_custom_axis_label = opt$use_custom_axis_label,
  my_feature_list = opt$my_feature_list,
  top_genes_labeled_only_if_passing_thresholds = opt$top_genes_labeled_only_if_passing_thresholds,
  label_size = opt$label_size,
  label_box_padding = opt$label_box_padding,
  label_force = opt$label_force,
  label_max_overlaps = opt$label_max_overlaps,
  custom_significance_label = opt$custom_significance_label,
  custom_log_fold_change_label = opt$custom_log_fold_change_label,
  plot_title = opt$plot_title,
  plot_subtitle = opt$plot_subtitle,
  y_limit = opt$y_limit,
  use_auto_axis_capping = opt$use_auto_axis_capping,
  auto_axis_capping_quantile = opt$auto_axis_capping_quantile,
  auto_axis_capping_min_y_limit = 0,
  auto_axis_capping_symmetric_x = opt$auto_axis_capping_symmetric_x,
  custom_x_axis_limits = opt$custom_x_axis_limits,
  x_limit_padding = opt$x_limit_padding,
  y_limit_padding = opt$y_limit_padding,
  plot_title_size = opt$plot_title_size,
  axis_title_size = opt$axis_title_size,
  axis_text_size = opt$axis_text_size,
  point_size = opt$point_size,
  image_width = opt$image_width,
  image_height = opt$image_height,
  resolution_dpi_ = resolved_resolution_dpi,
  output_file_path = file.path(results_dir, "volcano_plot.png"),
  color_not_significant = opt$color_not_significant,
  color_fold_change_only = opt$color_fold_change_only,
  color_significant_only = opt$color_significant_only,
  color_significant_and_fold_change = opt$color_significant_and_fold_change
)

write.csv(
  result,
  file.path(results_dir, "volcano_plot_data.csv"),
  row.names = FALSE
)

# Clean up default Rplots.pdf if created
default_rplots <- c(
  file.path(getwd(), "Rplots.pdf"),
  file.path(runtime_root, "Rplots.pdf"),
  file.path(runtime_root, "code", "Rplots.pdf")
)
for (path in unique(default_rplots[file.exists(default_rplots)])) {
  file.remove(path)
}

message("Volcano plots generated successfully in ", results_dir)
invisible(result)

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

# Define CLI options
# Note: DEG table can be uploaded via --deg_file or read from data asset at /data/deg_table/ (supports RDS/CSV/TSV)
option_list <- list(
  make_option("--deg_file", type = "character", default = NULL),
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
  make_option("--resolution_dpi_", type = "integer", default = 300),
  make_option("--color_not_significant", type = "character", default = "gray"),
  make_option("--color_fold_change_only", type = "character", default = "orange"),
  make_option("--color_significant_only", type = "character", default = "green4"),
  make_option("--color_significant_and_fold_change", type = "character", default = "red3")
)

parser <- OptionParser(
  usage = "Usage: %prog [options]\nDEG table can be uploaded via --deg_file or read from data asset at /data/deg_table/",
  option_list = option_list,
  description = "Generate enhanced volcano plots from differential expression analysis"
)

opt <- parse_args(parser, args = commandArgs(trailingOnly = TRUE))

# Convert string booleans to logical
opt$label_only_my_feature_list <- tolower(opt$label_only_my_feature_list) == "true"
opt$top_genes_labeled_only_if_passing_thresholds <- tolower(opt$top_genes_labeled_only_if_passing_thresholds) == "true"
opt$use_custom_axis_label <- tolower(opt$use_custom_axis_label) == "true"
opt$use_auto_axis_capping <- tolower(opt$use_auto_axis_capping) == "true"
opt$auto_axis_capping_symmetric_x <- tolower(opt$auto_axis_capping_symmetric_x) == "true"

# Find and read DEG table: uploaded file > data asset > example data (like L2P)
# Supports both RDS and CSV/TSV/TXT files

deg_data <- NULL
deg_table_path <- NULL

# Priority 1: Check for uploaded file
if (!is.null(opt$deg_file) && opt$deg_file != "" && file.exists(opt$deg_file)) {
  deg_table_path <- opt$deg_file
  message(sprintf("Loading DEG table from uploaded file: %s", deg_table_path))
  
  file_ext <- tolower(tools::file_ext(deg_table_path))
  if (file_ext == "rds") {
    deg_data <- readRDS(deg_table_path)
    
    # If RDS contains a list, extract the data frame
    if (is.list(deg_data) && !is.data.frame(deg_data)) {
      df_elements <- sapply(deg_data, is.data.frame)
      if (any(df_elements)) {
        deg_data <- deg_data[[which(df_elements)[1]]]
        message("Extracted data frame from list")
      } else {
        stop("ERROR: RDS file does not contain a data frame")
      }
    }
  } else if (file_ext == "csv") {
    deg_data <- read.csv(deg_table_path, stringsAsFactors = FALSE, check.names = FALSE)
  } else {
    # Assume TSV/TXT
    deg_data <- read.delim(deg_table_path, stringsAsFactors = FALSE, check.names = FALSE)
  }
}

# Priority 2: Check for data asset at /data/deg_table/
if (is.null(deg_data)) {
  message("Looking for DEG table in /data/deg_table/...")
  rds_files <- list.files("/data/deg_table", pattern = "\\.rds$", full.names = TRUE, recursive = TRUE, ignore.case = TRUE)
  csv_files <- list.files("/data/deg_table", pattern = "\\.(csv|tsv|txt)$", full.names = TRUE, recursive = TRUE, ignore.case = TRUE)
  
  if (length(rds_files) > 0) {
    deg_table_path <- rds_files[1]
    message(sprintf("Loading DEG table from RDS file: %s", deg_table_path))
    deg_data <- readRDS(deg_table_path)
    
    # If RDS contains a list, extract the data frame
    if (is.list(deg_data) && !is.data.frame(deg_data)) {
      df_elements <- sapply(deg_data, is.data.frame)
      if (any(df_elements)) {
        deg_data <- deg_data[[which(df_elements)[1]]]
        message("Extracted data frame from list")
      } else {
        stop("ERROR: RDS file does not contain a data frame")
      }
    }
    
  } else if (length(csv_files) > 0) {
    deg_table_path <- csv_files[1]
    message(sprintf("Loading DEG table from CSV/TSV file: %s", deg_table_path))
    
    file_ext <- tolower(tools::file_ext(deg_table_path))
    if (file_ext == "csv") {
      deg_data <- read.csv(deg_table_path, stringsAsFactors = FALSE, check.names = FALSE)
    } else {
      deg_data <- read.delim(deg_table_path, stringsAsFactors = FALSE, check.names = FALSE)
    }
  }
}

# Priority 3: Fallback to example data
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

# Results directory
results_dir <- if (dir.exists("/results")) "/results" else file.path(runtime_root, "results")
dir.create(results_dir, recursive = TRUE, showWarnings = FALSE)

# Source volcano plot function
source(file.path(runtime_root, "code", "functions", "Volcano_Plot_Enhanced.R"))

# Call volcano plot function
result <- volcano_plot_enhanced(
  deg_table = deg_table,
  pvalue_type = opt$pvalue_type,
  column_with_feature_id = opt$column_with_feature_id,
  significance_column = opt$significance_column,
  log2_fold_change_column = opt$log2_fold_change_column,
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
  resolution_dpi_ = opt$resolution_dpi_,
  output_file_path = file.path(results_dir, "volcano_plot.png"),
  color_not_significant = opt$color_not_significant,
  color_fold_change_only = opt$color_fold_change_only,
  color_significant_only = opt$color_significant_only,
  color_significant_and_fold_change = opt$color_significant_and_fold_change
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

# Code Ocean workflow-input helpers for the Volcano Plot adapter.
#
# The canonical OMIX module accepts an explicit DEG table path. This adapter
# additionally understands that a connected upstream capsule is mounted below
# /data, often in an opaque UUID directory.

find_workflow_csv <- function(base_dir = "/data") {
  all_csv <- list.files(
    base_dir,
    pattern = "\\.csv$",
    full.names = TRUE,
    recursive = TRUE,
    ignore.case = TRUE
  )
  matches <- all_csv[grepl("DEG", basename(all_csv), ignore.case = TRUE)]

  if (length(matches) > 1L) {
    stop(
      "ERROR: Multiple workflow DEG CSV files were found under ", base_dir,
      ". Specify an uploaded file or provide exactly one CSV whose filename ",
      "matches the regex 'DEG'.\\n", paste(matches, collapse = "\\n")
    )
  }

  if (length(matches) == 1L) matches[[1L]] else NULL
}

first_existing_column <- function(candidates, available_cols) {
  candidates <- candidates[!is.na(candidates) & nzchar(candidates)]
  match <- candidates[candidates %in% available_cols]
  if (length(match) > 0L) match[[1L]] else NULL
}

comparison_prefix <- function(columns, suffix_pattern) {
  sub(suffix_pattern, "", columns, ignore.case = TRUE, perl = TRUE)
}

resolve_workflow_volcano_columns <- function(df, pvalue_type = "nominal") {
  available_cols <- colnames(df)
  numeric_cols <- available_cols[vapply(df, is.numeric, logical(1))]
  use_adjusted <- identical(tolower(pvalue_type), "adjusted")

  significance_pattern <- if (use_adjusted) {
    "_(adjpval|padj|fdr)$"
  } else {
    "_(pval|p_value|pvalue)$"
  }
  significance_columns <- numeric_cols[
    grepl(significance_pattern, numeric_cols, ignore.case = TRUE, perl = TRUE)
  ]
  fold_change_columns <- numeric_cols[
    grepl("_(logfc|log2fc|log2_fold_change)$", numeric_cols, ignore.case = TRUE, perl = TRUE)
  ]

  sig_prefixes <- comparison_prefix(significance_columns, significance_pattern)
  fc_prefixes <- comparison_prefix(
    fold_change_columns,
    "_(logfc|log2fc|log2_fold_change)$"
  )
  shared_prefixes <- sig_prefixes[tolower(sig_prefixes) %in% tolower(fc_prefixes)]
  shared_prefixes <- unique(shared_prefixes)

  if (length(shared_prefixes) > 0L) {
    significance_columns <- unlist(lapply(shared_prefixes, function(prefix) {
      significance_columns[tolower(sig_prefixes) == tolower(prefix)][[1L]]
    }), use.names = FALSE)
    fold_change_columns <- unlist(lapply(shared_prefixes, function(prefix) {
      fold_change_columns[tolower(fc_prefixes) == tolower(prefix)][[1L]]
    }), use.names = FALSE)
  } else if (length(significance_columns) == 1L && length(fold_change_columns) == 1L) {
    # Support flat, unprefixed tables such as pval + logFC.
  } else {
    significance_columns <- character()
    fold_change_columns <- character()
  }

  feature_column <- first_existing_column(
    c("GeneName", "Gene Symbols", "Gene", "gene_name", "gene_symbol", "GeneSymbol", "Feature_ID", "FeatureID"),
    available_cols
  )
  missing <- c(
    if (is.null(feature_column)) "feature identifier",
    if (length(significance_columns) == 0L) "nominal or adjusted p-value",
    if (length(fold_change_columns) == 0L) "matching log2 fold-change"
  )
  if (length(missing) > 0L) {
    stop(
      "ERROR: Workflow input lacks required ", paste(missing, collapse = ", "),
      " column(s). Available columns: ", paste(available_cols, collapse = ", ")
    )
  }

  list(
    column_with_feature_id = feature_column,
    significance_columns = significance_columns,
    log2_fold_change_columns = fold_change_columns
  )
}

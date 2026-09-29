#!/usr/bin/env python3
"""Check the Code Ocean parameter surface against canonical interface v1."""

import json
import re
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
PANEL = json.loads((ROOT / ".codeocean/app-panel.json").read_text())
MAIN = (ROOT / "code/main.R").read_text()

EXPECTED_PANEL_ORDER = [
    "deg_table",
    "pvalue_type",
    "column_with_feature_id",
    "significance_column",
    "log2_fold_change_column",
    "p_value_threshold",
    "log2_fold_change_threshold",
    "choose_feature_to_label_by",
    "number_of_features_to_label",
    "label_only_my_feature_list",
    "my_feature_list",
    "top_genes_labeled_only_if_passing_thresholds",
    "label_size",
    "label_box_padding",
    "label_force",
    "label_max_overlaps",
    "use_custom_axis_label",
    "custom_significance_label",
    "custom_log_fold_change_label",
    "plot_title",
    "plot_subtitle",
    "y_limit",
    "use_auto_axis_capping",
    "auto_axis_capping_quantile",
    "auto_axis_capping_symmetric_x",
    "custom_x_axis_limits",
    "x_limit_padding",
    "y_limit_padding",
    "plot_title_size",
    "axis_title_size",
    "axis_text_size",
    "point_size",
    "image_width",
    "image_height",
    "resolution_dpi",
    "color_not_significant",
    "color_fold_change_only",
    "color_significant_only",
    "color_significant_and_fold_change",
]

assert PANEL["named_parameters"] is True
assert "help_text" not in (ROOT / ".codeocean/app-panel.json").read_text()

parameters = PANEL["parameters"]
by_name = {item["param_name"]: item for item in parameters}
assert [item["param_name"] for item in parameters] == EXPECTED_PANEL_ORDER
assert len(by_name) == len(parameters), "duplicate App Panel parameter name"

assert by_name["pvalue_type"]["extra_data"] == ["nominal", "adjusted"]
assert by_name["pvalue_type"]["default_value"] == "nominal"
assert by_name["label_max_overlaps"]["default_value"] == "Inf"
assert by_name["resolution_dpi"]["default_value"] == "300"
assert "resolution_dpi_" not in by_name
assert "output_dir" not in by_name  # Code Ocean owns /results; provenance records this binding.

for name in (
    "color_not_significant",
    "color_fold_change_only",
    "color_significant_only",
    "color_significant_and_fold_change",
):
    assert by_name[name]["type"] == "text"
    assert "extra_data" not in by_name[name]

cli_names = re.findall(r'make_option\(\s*"--([A-Za-z0-9_]+)"', MAIN)
assert cli_names[:-1] == EXPECTED_PANEL_ORDER[:1] + ["output_dir"] + EXPECTED_PANEL_ORDER[1:]
assert cli_names[-1] == "resolution_dpi_"
assert "deprecated; use `--resolution_dpi`" in MAIN

print("App Panel and adapter CLI contract checks passed")

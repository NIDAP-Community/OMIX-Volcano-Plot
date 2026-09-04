# OMIX Volcano Plot

Create publication-ready volcano plots from your differential expression analysis results.

## Canonical OMIX module

| Item | Location |
| --- | --- |
| Canonical module | [OMIX Volcano Plot](https://github.com/NIDAP-Community/OMIX/tree/main/modules/OMIX-Volcano-Plot) |
| Interface contract | [schemas/interface.yml](https://github.com/NIDAP-Community/OMIX/blob/main/modules/OMIX-Volcano-Plot/schemas/interface.yml) |
| Development contract | [OMIX module contract](https://github.com/NIDAP-Community/OMIX/blob/main/docs/module-contract.md) |
| Released source reference | [OMIX_MODULE_SOURCE.md](OMIX_MODULE_SOURCE.md) |

The canonical module owns scientific behavior, portable CLI operation, tests,
and the reusable input/output contract. This repository is its Code Ocean
deployment adapter.

## What this deployment adds

- The Code Ocean App Panel and capsule entry point.
- Uploaded and attached DEG-table discovery under `/data`.
- Capsule outputs under `/results` and the pinned runtime configuration.

## What Does This Do?

This tool visualizes differential gene expression data as volcano plots, helping you identify significantly up-regulated and down-regulated genes at a glance. Upload your DEG file or attach a data asset and get beautiful, customizable plots in seconds.

## Quick Start

### Try the Example Data

1. Click **Run** without attaching any data asset
2. The tool will generate example volcano plots automatically
3. View your results in the `/results` folder

### Use Your Own Data

**Option 1: Upload a File**
1. Click on **Upload DEG File (Optional)** in the App Panel
2. Select your CSV, TSV, or RDS file
3. Adjust thresholds and colors as needed
4. Click **Run**

**Option 2: Attach a Data Asset**
1. Prepare a data asset containing your differential expression results (RDS or CSV format)
2. Attach it using the **DEG Table** dataset parameter (without uploading a file)
3. Adjust thresholds and colors as needed
4. Click **Run**

**Note:** If you upload a file, it takes priority over the attached data asset.

The Gene ID Column accepts the column containing the symbols to print and
label. Leave it blank for automatic detection: Volcano prefers `GeneName`
(the OMIX workflow contract), then `Gene Symbols`, then common generic
identifier names. For another table, enter its exact column name in the App
Panel; Code Ocean does not provide a dynamic column dropdown for uploaded data.

### Use a Connected OMIX Workflow

When this capsule follows an upstream OMIX workflow, leave **Upload DEG File**
blank. It recursively searches `/data` for exactly one CSV whose filename
contains `DEG`—normally `DEG_Analysis.csv`—and uses it as the input. The
workflow table must contain a gene identifier plus matching `*_pval` and
`*_logFC` columns. Nominal `*_pval` columns are the default; select
**adjusted** in the App Panel to use matching adjusted p-value columns.

If multiple matching CSV files are attached, the capsule stops and lists them
so the upstream connection can be made unambiguous.

## What Data Do I Need?

Your data file (RDS or CSV) should include these three types of columns:

### 1. Gene/Feature Identifier Column
**Expected names:** `Gene`, `Feature_ID`, `FeatureID`, `gene`, `gene_id`, or any text column
**Example:** STAT1, IRF7, ENSG00000012345

### 2. P-value Columns (one or more comparisons)
**For nominal p-values, column names should contain:** `pval`, `p_value`, or `pvalue`
**Examples:** `Treatment_vs_Control_pval`, `GroupA-GroupB_pval`

**For adjusted p-values, column names should contain:** `adjpval`, `adj`, or `fdr`
**Examples:** `Treatment_vs_Control_adjpval`, `GroupA-GroupB_fdr`

### 3. Log2 Fold Change Columns (matching your p-value comparisons)
**Expected patterns:** `logfc`, `log2fc`, or `log2_fold_change`
**Examples:** `Treatment_vs_Control_logFC`, `GroupA-GroupB_log2FC`

### Supported File Formats
- **RDS files** - R data frames (automatically extracts data frames from lists)
- **CSV files** - Comma-separated values
- **TSV/TXT files** - Tab-separated values

### Column Naming Tips
- Use **consistent comparison names** across p-value and fold change columns
- The tool automatically detects columns based on these patterns (case-insensitive)
- If you have multiple comparisons (e.g., A-B, A-C, B-C), include the comparison name in each column
- Example full column names: `GeneSymbol`, `TreatmentA_vs_Control_pval`, `TreatmentA_vs_Control_adjpval`, `TreatmentA_vs_Control_logFC`
- You can also manually specify column names in the App Panel if auto-detection doesn't work

## Key Features

✨ **P-value Type Selection** - Choose between nominal or adjusted (FDR) p-values  
📂 **Flexible Data Input** - Upload files OR attach data assets for maximum convenience  
📄 **Multiple Format Support** - Reads RDS, CSV, and TSV files  
🔍 **Auto Column Detection** - Automatically finds gene IDs, p-values, and fold changes  
📊 **Auto Axis Capping** - Reduces outlier impact for better visualization  
🎨 **Custom Colors** - Select from curated color palettes for each quadrant (organized light to dark for easy selection)  
🏷️ **Smart Gene Labeling** - Automatically labels top significant genes  
📐 **Flexible Layout** - Adjust fonts, sizes, and dimensions  
🔧 **Advanced Controls** - Fine-tune thresholds, axis limits, and label spacing

### Default Color Scheme
- **Non-significant points:** gray
- **Fold change only:** orange  
- **Significant only:** green4
- **Significant + fold change:** red3

## What Will I Get?

- **Volcano plot images** (PNG format, publication-ready at 300 DPI)
- **One plot per comparison** in your data
- **Automatically named files** indicating the comparison and p-value type used

## Need Help?

- **Example data included** - Just click Run to see how it works
- **App Panel tooltips** - Hover over any parameter for guidance
- **Column selection** - Leave column parameters blank for automatic detection
- **Support** - Contact your Code Ocean administrator

## Citation

If you use this tool in your research, please cite the OMIX Volcano Plot capsule and Code Ocean platform.

---

## For developers

Read [AGENTS.md](AGENTS.md) and [OMIX_MODULE_SOURCE.md](OMIX_MODULE_SOURCE.md)
before editing. Technical implementation details are available in
[`code/DEVELOPER.md`](code/DEVELOPER.md). Reusable scientific changes belong in
the canonical OMIX module and are exported here only after validation.

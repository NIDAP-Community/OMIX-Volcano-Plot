# Changelog

All notable deployment-adapter changes are documented here. Scientific changes
belong to the canonical OMIX module and are not maintained in this repository.

## Unreleased

- Select the OMIX Visualization v2 Code Ocean starter environment and remove
  redundant capsule-local R package installation.
- Treat the special `Inf` label-overlap value as text in the App Panel so Code
  Ocean accepts the canonical unlimited-overlap default; the R CLI still
  parses it as a numeric infinity.
- Export the complete canonical OMIX Volcano Plot R source at commit
  `eee4433cd74d0ce9bd1daba1571ca6312cba7ea2` byte-for-byte.
- Align the adapter CLI and App Panel with canonical interface version 1,
  including `deg_table`, unlimited label overlap, and public `resolution_dpi`.
- Retain `resolution_dpi_` only as a hidden, deprecated CLI compatibility alias.
- Document Code Ocean's managed `/results` translation and pending runtime,
  Syncweaver, Beacon, and Code Ocean evidence.
- Move adapter-only input discovery out of the managed scientific export tree.
- Record the canonical public `r-visualization` tag and immutable GHCR digest;
  the Code Ocean environment is selected and builds, while its immutable
  imported digest remains pending.
- Record successful linked-capsule validation run `865194` against adapter
  commit `eb57569a276df25f4364ff27fa4e114497066937`, including the attached
  DEG input, default named parameters, detected comparisons, output CSV, and
  three visually inspected plots. The capsule's newline-only
  `environment.json` working-tree difference, imported Code Ocean digest, and
  release identifiers remain pending.

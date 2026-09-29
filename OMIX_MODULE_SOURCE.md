# Canonical OMIX Module Source

## Canonical module

- **Module:** [OMIX Volcano Plot](https://github.com/NIDAP-Community/OMIX/tree/main/modules/OMIX-Volcano-Plot)
- **Canonical path:** `modules/OMIX-Volcano-Plot/`
- **Canonical module version:** `1.0.0`
- **Canonical interface version:** `1`
- **Runtime profile:** `r-visualization`
- **Canonical release tag:** Pending — baseline tag not yet established.
- **Canonical source reference:** [`eee4433cd74d0ce9bd1daba1571ca6312cba7ea2`](https://github.com/NIDAP-Community/OMIX/commit/eee4433cd74d0ce9bd1daba1571ca6312cba7ea2)
- **Interface schema:** [schemas/interface.yml](https://github.com/NIDAP-Community/OMIX/blob/main/modules/OMIX-Volcano-Plot/schemas/interface.yml)
- **Module contract:** [OMIX module contract](https://github.com/NIDAP-Community/OMIX/blob/main/docs/module-contract.md)

## Exported scientific files

The complete canonical `R/` tree at the source reference above is exported
byte-for-byte into `code/functions/`. No adapter-side scientific edits are
permitted.

| Canonical file | Adapter copy | SHA-256 (both files) |
| --- | --- | --- |
| `R/Volcano_Plot_Enhanced.R` | `code/functions/Volcano_Plot_Enhanced.R` | `75df94195458c63130edaab5a2ee0a90c88ca9aa859591c6810d3eec5948673b` |

## Adapter translations

- `code/main.R` accepts the canonical public CLI controls and calls the
  exported scientific function.
- `deg_table` may be an explicit upload or an unambiguous attached/workflow
  input discovered by `code/adapter/workflow_input.R`.
- `output_dir` remains a canonical CLI control. The App Panel hides it because
  Code Ocean manages the output mount; the canonical default `results` is
  translated to `/results` when that mount exists. An explicitly supplied
  non-default path is honored.
- `resolution_dpi` is the only public resolution control. The adapter accepts
  the historical `--resolution_dpi_` spelling as a hidden, deprecated CLI
  compatibility alias, emits a warning, and maps it to the canonical control.
  The alias is not exposed in the App Panel and does not change the scientific
  function's internal `resolution_dpi_` argument.

<!-- omix-adapter-contract: {"aliases": {}, "hidden_inputs": [{"canonical": "output_dir", "binding": "Code Ocean /results; code/main.R maps the canonical default results to /results when the managed mount exists"}]} -->

## Adapter release record

| Field | Recorded value |
| --- | --- |
| Adapter version | Pending — baseline tag not yet established. |
| Adapter release tag | Pending. |
| Platform release | Pending Code Ocean validation; local tests are not platform evidence. |
| Runtime identity | Pending immutable image digest under [OMIX issue #43](https://github.com/NIDAP-Community/OMIX/issues/43). |
| Syncweaver lock | Pending generated mapping under [OMIX issue #44](https://github.com/NIDAP-Community/OMIX/issues/44); do not hand-author `.syncweaver-lock.json`. |

See the [OMIX versioning and release policy](https://github.com/NIDAP-Community/OMIX/blob/main/docs/versioning-and-releases.md).
The source commit, adapter tag, platform release, and runtime identity are
separate records. None of the pending release fields above may be inferred
from a local or GitHub Actions test.

## Adapter-only support code

`code/adapter/workflow_input.R` resolves Code Ocean workflow and attached-data
inputs. It is adapter support code, not an exported scientific function.

## Ownership and synchronization

The canonical module owns scientific functions, portable CLI behavior,
schemas, tests, and scientific documentation. This adapter owns deployment UI,
input discovery, result-path translation, runtime selection, and the platform
entry point.

Reusable changes must be made and reviewed in the canonical module first.
Until Syncweaver manages this mapping, Harbor exports the complete canonical
`R/` tree without edits and records the immutable source and hashes here.
Beacon independently checks byte parity and interface translation before any
release; Code Ocean validation remains a separate required step.

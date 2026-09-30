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

<!-- omix-runtime-provenance: {"runtime_profile":"r-visualization","published_image":"ghcr.io/nidap-community/omix-r-visualization","published_tag":"r4.4.3-v2","published_digest":"sha256:1d9f453b49412aa05e9d3420cd4b1b4ea0beac4923cb40572af38b0ae2a46830","published_immutable_reference":"ghcr.io/nidap-community/omix-r-visualization@sha256:1d9f453b49412aa05e9d3420cd4b1b4ea0beac4923cb40572af38b0ae2a46830","adapter_base_image":"codeocean/py-r:python3.10.12-R4.2.3-IRkernel-ubuntu22.04","adapter_base_image_digest":null,"adapter_digest_status":"pending_code_ocean_resolution","runtime_profile_alignment_status":"pending_runtime_reconciliation","code_ocean_environment_id":null,"capsule_run":null} -->

## Adapter release record

| Field | Recorded value |
| --- | --- |
| Adapter version | Pending — baseline tag not yet established. |
| Adapter release tag | Pending. |
| Platform release | Pending Code Ocean validation; local tests are not platform evidence. |
| Canonical runtime profile | `r-visualization`, as declared by the canonical module. |
| Published OMIX runtime | Tag `ghcr.io/nidap-community/omix-r-visualization:r4.4.3-v2`; immutable public identity `ghcr.io/nidap-community/omix-r-visualization@sha256:1d9f453b49412aa05e9d3420cd4b1b4ea0beac4923cb40572af38b0ae2a46830`. |
| Adapter-selected base image | `codeocean/py-r:python3.10.12-R4.2.3-IRkernel-ubuntu22.04` from `.codeocean/environment.json`; this legacy selection does **not** align with the canonical runtime profile and its digest is **Pending Code Ocean resolution**. |
| Runtime build evidence | [Starter Environments run 33779788678](https://github.com/NIDAP-Community/OMIX/actions/runs/33779788678) built, verified, inventoried, and published `r-visualization:v2`; [GHCR version 1205968442](https://github.com/orgs/NIDAP-Community/packages/container/omix-r-visualization/1205968442) independently maps the version tag to the recorded digest. Post-publication package-set re-verification remains pending in the canonical release manifest. |
| Code Ocean environment identity | **Pending** — no immutable environment-release identifier is recorded. |
| Capsule run | A representative Code Ocean run using the canonical runtime profile is **Pending**; GitHub or local checks are not platform validation. |
| Syncweaver lock | Pending generated mapping under [OMIX issue #44](https://github.com/NIDAP-Community/OMIX/issues/44); do not hand-author `.syncweaver-lock.json`. |

The public image identity above is also recorded in the canonical
[`release-manifest.json`](https://github.com/NIDAP-Community/OMIX/blob/eee4433cd74d0ce9bd1daba1571ca6312cba7ea2/starter-environments/release-manifest.json).
It is the intended portable runtime candidate, not evidence that this adapter
has selected or passed inside that runtime on Code Ocean. The source commit,
adapter tag, public image tag and digest, Code Ocean environment identity,
capsule run, and platform release are separate records. None of the pending
release fields above may be inferred from a local or GitHub Actions test.
Runtime reconciliation remains tracked by
[OMIX issue #43](https://github.com/NIDAP-Community/OMIX/issues/43).

See the [OMIX versioning and release policy](https://github.com/NIDAP-Community/OMIX/blob/main/docs/versioning-and-releases.md).

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

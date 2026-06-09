# Chip Support Request — Chip Support Application

> Submit this form to sig-chip to request adding a new chip to the FlagOS support matrix.
> See the approval process in [sig-chip/README.md](README.md).
>
> **Startup phase note**: When sig-chip has no Chair, the approval process is simplified to a single tier — directly approved by TSC (or by the 众智FlagOS社区 (ZhongZhi FlagOS Community) before TSC is established). In this case, "sig-chip Assessment" and "TSC Approval" in the approval record table are merged, filled in by the same approver.

---

## Basic Information

| Field | Content |
|------|------|
| **Vendor Name** | (Chinese/English) |
| **Chip Model** | |
| **Chip Type** | Data Center Training / Data Center Inference / Edge Inference |
| **SDK Name and Version** | e.g.: CUDA 13.0, DTK 26.04 |
| **SDK License Type** | (Must be confirmed compatible with FlagOS open source license) |
| **Application Date** | YYYY-MM-DD |

## Technical Information

| Field | Content |
|------|------|
| **Compute Precision Support** | FP32 / FP16 / BF16 / INT8 / FP8 / ... |
| **VRAM/Memory Size** | |
| **Interconnect Bandwidth** | |
| **PCIe Version** | |

## CI Resource Commitment

> Chip vendors must provide CI resources (self-hosted runners or hardware access).

| Field | Content |
|------|------|
| **CI Resource Type** | Self-hosted GitHub runner / Remote hardware access / Other |
| **Available Node Count** | |
| **Estimated Delivery Date** | |
| **Point of Contact** | Name / GitHub / Email |

## Initial Contributors

At least 2 engineers are required for chip bring-up:

| Name | GitHub | Role | Commitment Level |
|------|--------|------|----------|
| | | | |
| | | | |

## Compliance Confirmation

- [ ] SDK License is compatible with FlagOS open source license (Apache 2.0)
- [ ] Confirmed that code contributions will follow DCO (Developer Certificate of Origin) requirements
- [ ] Acknowledged and accepted the FlagOS [Code of Conduct](../../CODE_OF_CONDUCT.md)

---

## Approval Record

| Stage | Date | Approver | Result |
|------|------|--------|------|
| sig-chip Assessment | | | |
| TSC Approval | | | |
| CI Delivery Confirmation | | | |
| Bring-up Complete | | | |

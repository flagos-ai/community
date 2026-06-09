# SIG Annual Report Guide

## Purpose

- Keep the TSC and community informed about the health of each SIG
- Help Chairs identify areas for improvement
- Provide a basis for resource allocation (CI, documentation, community operations support)
- Serve as a reference for whether a SIG should remain active

---

## Submission Timeline

- Once per calendar year, due by **January 31** each year
- Newly established SIGs (less than 6 months old) may defer to the following year

---

## Report Template

```markdown
# SIG-xxx Annual Report — YYYY

## 1. Basic Information

- **SIG Name**:
- **Chair**: @github-id
- **Tech Lead**: @github-id
- **Reporting Period**: YYYY-01 to YYYY-12

## 2. Membership

| Role | Members at Start | Members at End | Change |
|------|------------------|----------------|--------|
| Chair | | | |
| Tech Lead | | | |
| Approver | | | |
| Reviewer | | | |
| Active Members (≥1 PR this year) | | | |

- New promotions:
- Departures:
- Are any key roles vacant? If so, what is the plan to fill them?

## 3. Module Health

| Module / Subproject | Status (✅/⚠️/❌) | Notes |
|---------------------|-------------------|-------|
| xxx | ✅ | Maintained normally |
| xxx | ⚠️ | Insufficient Approvers |
| xxx | ❌ | No active maintainer |

## 4. Contribution Data

- Merged PRs this year:
- Active Contributors (≥1 PR):
- External contributor ratio:
- Year-over-year trend: ↑/↓/→

## 5. FEPs

| FEP | Status | Notes |
|-----|--------|-------|
| FEP-NNNN | Implemented | |
| FEP-NNNN | Implementable | |

## 6. Achievements

- Top 3 achievements this year:
  1.
  2.
  3.

## 7. Challenges

- Key challenges currently faced:
- Support needed from the TSC or community:

## 8. Next Year's Plan

- Top 3 goals for the coming year:
  1.
  2.
  3.

## 9. Additional Notes

- Other items to communicate to the TSC and community:
```

---

## Review Process

1. The SIG Chair submits `annual-report-YYYY.md` under `sigs/sig-xxx/`
2. The TSC reviews within 2 weeks
3. The TSC may request supplementary explanation or suggest improvements
4. The TSC includes annual report summaries in the quarterly community all-hands briefing

---

## Health Assessment

The TSC evaluates SIG health based on the annual report and other signals (PR activity, issue response time, meeting attendance):

| Status | Meaning | TSC Action |
|--------|---------|------------|
| 🟢 Healthy | Operating normally | None |
| 🟡 Watch | Risk factors present (insufficient Approvers, declining activity) | TSC discusses improvement plan with the Chair |
| 🔴 At Risk | Key roles long-term vacant, modules unmaintained | TSC considers merging/disbanding or appointing an interim Chair |

---

- [GOVERNANCE.md](../GOVERNANCE.md) — SIG disbanding process

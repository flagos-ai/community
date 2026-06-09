# TSC Election Process

This document defines the FlagOS election process for TSC members during the maturity phase. Bootstrap phase TSC members are appointed directly by the ZhongZhi FlagOS Community and are not subject to this process.

---

## I. Election Cycle

### Regular Elections

- Held every **2 years**
- Election takes place 1 month before the end of the current term
- New TSC members take office within 2 weeks after the election concludes

### By-Elections

A by-election is held within 2 months when:
- A TSC member resigns
- A TSC member is removed due to inactivity or CoC violation
- The number of TSC members falls below 4 (bootstrap phase minimum)

Members elected in a by-election serve the remainder of the term.

### Staggered Terms

In the first maturity-phase election, seats in the top half by vote count serve 2-year terms, and seats in the bottom half serve 1-year terms (ties resolved by drawing lots). Thereafter, roughly half the seats are up for election each cycle to avoid a complete turnover.

---

## II. Voter Eligibility

### Voting Rights

Community members who satisfy the following criteria within the 12 months prior to the election announcement date are eligible to vote:

- At least 1 merged PR in any FlagOS module repository
- Not suspended from the community by the TSC due to a CoC violation

### Voter Roll

1. The TSC publishes a draft voter roll 2 weeks before the nomination period begins
2. The community has 1 week to raise objections to the roll
3. The TSC adjudicates objections and publishes the final roll

### One Person, One Vote

Regardless of how many modules a person has contributed to, each person gets one vote. Identity is determined by GitHub ID.

---

## III. Candidate Eligibility

### Nomination Criteria (any one of the following)

- Current or former SIG Chair or Tech Lead
- Former SIG Approver for ≥12 months
- Endorsed by ≥2 current TSC members (with written endorsement rationale)

### Employer Cap

No more than **2 seats** on the TSC may be held by members of the same organization/company. If the election results would produce more than 2 seats, the 2 candidates with the highest votes are seated, and the remaining seats pass to the next-ranked candidates.

After election, TSC members must follow the conflict-of-interest disclosure provisions in [GOVERNANCE.md](../GOVERNANCE.md) when day-to-day decisions involve employer interests.

### Nomination Method

- Self-nomination: a candidate declares candidacy in the election Issue
- Peer nomination: endorsed by ≥2 eligible voters (the nominee must accept the nomination)

---

## IV. Election Process

```
Nomination Period (2 weeks) → Public Comment Period (1 week) → Voting Period (1 week) → Results Announcement
```

### 1. Nomination Period (2 weeks)

- The TSC Chair creates an election Issue in the community repo
- Candidates reply in the Issue with a candidacy statement containing:
  - Brief bio and FlagOS contribution history
  - Campaign statement (views on project direction, planned initiatives)
  - Affiliated organization/company
- The candidate list is locked once the nomination period ends

### 2. Public Comment Period (1 week)

- The candidate list and campaign statements are published on GitHub
- Community members may ask candidates questions in the Issue
- Candidates may choose to respond or update their campaign statements

### 3. Voting Period (1 week)

- Anonymous ranked-choice voting is used
- Recommended tools: [Elekto](https://elekto.dev/) or Condorcet Internet Voting Service
- Each voter ranks candidates in order of preference (1, 2, 3, ...)
- Voting is conducted via email or a dedicated voting link to ensure anonymity

### 4. Vote Counting and Results

- Votes are counted using the Condorcet or Schulze method
- Results are sorted by vote count from highest to lowest
- The employer cap is applied (≤2 seats per organization)
- The TSC Chair announces the final results in the Issue

### 5. Challenge Period

Within 72 hours after results are announced, any voter may challenge the election process. The TSC adjudicates within 1 week.

---

## V. Election Administration

### Election Officers

The TSC designates 2 Election Officers before the election begins:

- Must not be current TSC members or candidates
- Responsible for voter roll verification, voting tool configuration, and vote counting
- Preference given to individuals from different organizations/companies

### Election Schedule Template

```markdown
# FlagOS TSC Election — YYYY

| Date | Phase |
|------|-------|
| YYYY-MM-DD | Voter roll published |
| YYYY-MM-DD | Nomination period begins |
| YYYY-MM-DD | Nomination period ends, public comment period begins |
| YYYY-MM-DD | Public comment period ends, voting period begins |
| YYYY-MM-DD | Voting period ends |
| YYYY-MM-DD | Results announced |
| YYYY-MM-DD | New TSC takes office |
```

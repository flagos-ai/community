# Meeting Facilitation Guide

This document defines the operating norms for all formal FlagOS community meetings. It applies to TSC regular meetings, SIG regular meetings, and community all-hands meetings.

---

## I. Roles and Responsibilities

Each meeting requires three roles, which may be filled by the same person:

| Role | Responsibility | Who Serves |
|------|----------------|------------|
| **Chair / Facilitator** | Publishes the agenda, manages time, drives topics, confirms resolutions | TSC Chair or SIG Chair |
| **Facilitator / Moderator** | Ensures everyone has a chance to speak, prevents digression, handles conflict | Preferably a different person from the Chair |
| **Note Taker / Scribe** | Records discussion highlights, resolutions, and action items | Rotating role, designated on the spot |

> When the Chair is absent, the Tech Lead or an Approver designated on the spot serves as substitute.

---

## II. Pre-Meeting Preparation

### Agenda Setting (≥24h before meeting)

The Chair is responsible for creating the meeting agenda file in the following format:

```markdown
# <TSC / SIG-xxx> Regular Meeting — YYYY-MM-DD

**Time**: YYYY-MM-DD HH:MM (UTC+8), estimated XX minutes
**Location**: <Tencent Meeting / Zoom link>
**Chair**: @github-id
**Notes**: @github-id (designated on the spot)

---

## Agenda

### 1. [Info] Action Item Review from Previous Meeting (5min)
- [ ] @someone: xxx
- [ ] @someone: xxx

### 2. [Discuss] Topic Title (10min)
- Background: (link or one-liner)
- Desired Outcome: directional input / concrete decision / assign owner

### 3. [Decide] Topic Title (15min)
- Proposal: (link to PR/Issue)
- Needs: vote to approve

### 4. [Info] Topic Title (5min)
- Sync on latest progress

### 5. Other Business (remaining time)
- ...
```

### Agenda Item Labeling Convention

Each agenda item must carry a type label:

| Label | Meaning | Desired Outcome |
|-------|---------|-----------------|
| `[Info]` | Status sync, no discussion needed | Members are informed |
| `[Discuss]` | Exchange of views needed, no on-the-spot decision needed | Directional consensus, assign owner |
| `[Decide]` | A decision must be made during the meeting | Resolution, vote result |

### Agenda Publication

- The Chair submits the agenda as a PR to `sigs/sig-xxx/meetings/` or the TSC-designated directory at least 24h before the meeting
- Simultaneously share the link in the WeChat group / GitHub Discussions
- Late topics (<24h) may be added under "Other Business" but cannot be `[Decide]` topics

---

## III. During the Meeting

### Time Management

| Segment | Duration | Notes |
|---------|----------|-------|
| Opening + Action Item Review | 5min | Quick review of last meeting's action items |
| Each Topic | Per agenda allocation | Chair must enforce; call time at 2min over |
| Other Business / Open Discussion | Remaining time | No more than 20% of total duration |
| Wrap-up + Notes Confirmation | 5min | Confirm resolutions, action items, next meeting time |

### Discussion Norms

1. **One person speaks at a time.** The Chair or Facilitator manages the speaking order.
2. **Stay on topic.** If discussion goes off track, the Facilitator records the tangent in a parking lot for later discussion.
3. **Give everyone a chance.** The Facilitator ensures non-Chair members have space to speak.
4. **Disagreement:** Each side states its reasoning → Facilitator seeks consensus → if disagreement persists, escalate per the decision rules (lazy consensus → vote → escalate to TSC).

### Decisions

In-meeting decisions follow the [Decision Playbook](decision-guide.md):
- Non-material decisions: passed once the Chair confirms no objection
- Material decisions: vote on the spot or convert to asynchronous vote
- All resolutions are marked `[Resolution]` in the minutes

---

## IV. Post-Meeting

### Minutes Publication (within 48h after meeting)

The Note Taker supplements the agenda file with meeting minutes and submits a PR for merging:

```markdown
# <TSC / SIG-xxx> Regular Meeting Minutes — YYYY-MM-DD

...

## Resolutions

- [Resolution] xxx (lazy consensus / vote x/x)
- [Resolution] xxx

## Action Items

- [ ] @someone: xxx (due YYYY-MM-DD)
- [ ] @someone: xxx (due YYYY-MM-DD)

## Next Meeting

YYYY-MM-DD HH:MM (UTC+8)
```

### Challenge Period After Minutes Publication

- **72 hours** after minutes are published, members who did not attend may raise objections
- No objection → resolutions take effect
- Objection → Chair determines whether re-discussion is needed

### Action Item Tracking

- At the start of each meeting, first review the previous meeting's action items
- Action items incomplete for 2 consecutive meetings → Chair does a 1:1 check-in with the assignee to confirm whether the deadline needs adjustment or the item needs reassignment

---

## V. Asynchronous Participation

Members unable to attend regular meetings in real time may participate via:

1. **Before the meeting**: leave comments expressing views on the agenda PR
2. **After the meeting**: read the minutes and raise feedback within the 72h challenge period
3. **Ongoing**: participate in discussions via GitHub Discussions, Issue/PR comments

---

## VI. Meeting Cancellation and Rescheduling

- The Chair must notify cancellation at least **4 hours** before the meeting
- If a meeting is canceled for 2 consecutive times due to insufficient attendance (≤2 people) → the Chair must report the reason to the TSC
- Meetings during weeks with statutory holidays are automatically canceled

---

## VII. Differences: TSC Regular Meetings vs. SIG Regular Meetings

| Dimension | TSC Regular Meeting | SIG Regular Meeting |
|-----------|---------------------|---------------------|
| Frequency | Biweekly, 60min | Biweekly (staggered with TSC), 45min |
| Participants | TSC members (TSC members may invite others as observers) | Open to the community |
| Agenda Submission Deadline | 48h before meeting | 24h before meeting |
| Primary Topics | Cross-SIG coordination, release planning, new SIG approval, governance changes | Module technical direction, PR review, FEP advancement, member onboarding |
| Recording | Recommended; record and upload (with participant consent) | Recommended but not required |
| Minutes Publication | Within 48h after meeting | Within 48h after meeting |

---

## VIII. Community All-Hands Meeting

Held quarterly, 90min.

**Agenda Structure:**
1. Project status update (TSC Chair, 15min)
2. Quarterly highlights from each SIG (each Chair 5min × 7 SIGs)
3. Community contributor recognition (5min)
4. Themed talk or Panel discussion (30min)
5. Open Q&A (remaining time)

**Organization:**
- TSC Chair organizes; SIG Chairs provide materials
- Announce at least 2 weeks in advance
- Record and upload (Bilibili / YouTube; participants must be informed at the start of the meeting and consent to recording)

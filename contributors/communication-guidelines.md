# Communication Channel Operations Guide

This document defines the creation, operation, and archival norms for FlagOS community communication channels.

---

## I. Channel Overview

| Channel | Purpose | Management | Responsible Party |
|---------|---------|------------|-------------------|
| **GitHub Issues** | Bug reports, feature requests | Module OWNERS handle triage (see [Issue Triage Guide](issue-triage.md)) | SIG Triage Lead / Approver |
| **GitHub Discussions** | Technical discussions, Q&A, community announcements | Community Manager + TSC | TSC |
| **GitHub Pull Requests** | Code review, FEP approval | OWNERS mechanism | SIG Approver |
| **WeChat Groups** | Day-to-day chat, quick Q&A, intra-SIG coordination | Managed by each SIG Chair | SIG Chair |
| **WeChat Official Account** | Release announcements, community news | Community Operations Team | ZhongZhi FlagOS Community |
| **Bilibili / YouTube** | Meeting recordings, tech talk videos | TSC + SIG Chair | TSC |
| **Mailing List** (planned) | Formal announcements, cross-community coordination | TSC | TSC |

---

## II. GitHub Discussions

### Categories

| Category | Purpose | Example |
|----------|---------|---------|
| 📢 **Announcements** | Release announcements, community event notices | "FlagOS v2.1 Released" |
| 💬 **General** | General technical discussion | "How to use custom kernels in FlagAttention?" |
| 🙏 **Q&A** | Questions and help requests | "FlagGems build error on a certain chip" |
| 💡 **Ideas** | Feature suggestions and brainstorming | "Discussion on unifying the Device API" |
| 🛠️ **Show & Tell** | Community members sharing their work | "I trained a 7B model with FlagScale" |

### Operations Norms

- **Response time**: new posts should receive a reply within 2 business days (by any community member or TSC member)
- **Marking answers**: In the Q&A category, the OP or a Moderator may mark the correct answer
- **Archival**: posts inactive for more than 6 months are automatically locked (GitHub default behavior)
- **Moderator**: TSC members and SIG Chairs serve as moderators

---

## III. WeChat Groups

### Group Structure

| Group | Members | Purpose |
|-------|---------|---------|
| **FlagOS Community Main Group** | All community members | Announcements, general discussion |
| **TSC Working Group** | TSC members | Day-to-day coordination |
| **SIG-xxx Group** | SIG members | Intra-SIG discussion |

### Operations Norms

- **Joining**: post a request in GitHub Discussions; invited by a SIG Chair or TSC member
- **Group Notice**: pin SIG regular meeting times, meeting links, important announcements
- **Discussion Norms**:
  - Technical discussions should preferably move to GitHub Issues/Discussions for archival
  - Decision-related discussions must have a corresponding record on GitHub (PR/Issue); WeChat is only supplementary
  - Follow the [Code of Conduct](../CODE_OF_CONDUCT.md)
- **Group Management**: handled by the SIG Chair or a designated admin
  - May remove long-inactive members (optional, not mandatory)
  - Handle CoC violations

---

## IV. Meeting Recordings and Videos

### Recording Requirements

- TSC regular meetings: recording recommended (with verbal consent from participants)
- SIG regular meetings: recording at each SIG's discretion
- Community all-hands meetings: recording mandatory

### Upload Norms

- **Platform**: Bilibili (domestic) / YouTube (international)
- **Title format**: `[FlagOS] <SIG/TSC> Regular Meeting — YYYY-MM-DD`
- **Upload deadline**: within 1 week after the meeting
- **Playlists**: one playlist per SIG, one playlist for TSC

### Administrators

- Each SIG Chair manages their SIG's playlist
- TSC handles video uploads for community all-hands meetings

---

## V. WeChat Official Account

### Content Published

- Release announcements
- Community event notices
- SIG quarterly highlights
- Contributor stories
- Technical blog posts

### Publishing Frequency

- Mandatory upon each release
- Monthly community newsletter (optional)
- Major event announcements

### Operations

- Managed by the ZhongZhi FlagOS Community Operations Team
- Content sources: materials supplied by SIG Chairs, reviewed by TSC

---

## VI. Channel Creation

### Creating a New WeChat Group

1. SIG Chair proposes the need
2. TSC confirms
3. Chair creates the group and sets the group notice
4. Update contact information in `sigs/sig-xxx/README.md`

### Creating a New GitHub Discussion Category

Submit a PR to update the community repo's Discussion configuration; approved by TSC.

### Requesting a Mailing List

Planned; to be established when the community reaches a larger scale.

---

## VII. Channel Archival

- When a SIG is disbanded, its WeChat group is dissolved by the Chair after posting an announcement in the group (at least 1 week's notice)
- GitHub Discussions are not deleted; historical records are preserved
- Video playlists are not deleted but marked "Archived"

---

## VIII. Moderation

All channel interactions are governed by the [Code of Conduct](../CODE_OF_CONDUCT.md).

- **Violation handling**: report to contact@flagos.io
- **Moderator authority**: TSC members may carry out temporary moderation (post deletion, muting) in any channel, with retrospective TSC confirmation within 72 hours
- **Appeal**: moderated individuals may submit a written appeal to the TSC; the TSC adjudicates within 2 weeks

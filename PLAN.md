# Restructure Navigation: 6 Tabs — Home | Wallet | Pacts | Coach | Hub | Profile

## Summary

Restructure the app from 5 tabs to 6 tabs, redistributing features from the old "Tools" and "Games" tabs into new dedicated tabs: **Pacts** (friend challenges), **Coach** (AI coach + crisis tools + impulse control), and **Hub** (games + spending tools).

---

## Features

- **Pacts tab** — Dedicated first-class tab for the friend challenge system, rebranded from "Challenges" to "Pacts"
- **Coach tab** — Emergency quick-access tools (SOS, Pause & Breathe, HALT Check) at the top, AI Money Coach as the main feature, plus impulse control tools and DNS blocking
- **Hub tab** — All games content (quests, vault, cards, weekly challenge, leaderboard, stats) plus spending tools (Budget Tracker, Ghost Budget, Vibe Check)
- **Renamed strings** — All user-facing "Challenge" text becomes "Pact" throughout the app
- **Tools tab removed** — Its contents are fully redistributed across Coach and Hub

---

## Tab Bar (6 tabs, left to right)

1. **Home** — house icon (unchanged)
2. **Wallet** — wallet icon (unchanged)
3. **Pacts** — person.2.fill icon — friend pact system
4. **Coach** — brain.head.profile.fill icon — AI coach + crisis + impulse tools
5. **Hub** — square.grid.2x2.fill icon — games + spending tools
6. **Profile** — person.circle icon (unchanged)

---

## Pages / Screens

### Pacts Tab (new)
- Same content as the old ChallengesHubView, rebranded
- Navigation title: "Pacts"
- Empty state: "Start a Pact with friends to save money together"
- Section headers: "Active Pacts", "Available Pacts"
- CTA: "Start" / "Create a Pact"
- Join section at top with 6-character invite code text field + "Join" button
- No dismiss button (it's a tab now, not a fullScreenCover)

### Coach Tab (new)
- **Emergency Quick Access** — Three large always-visible buttons at top: SOS (red), Pause & Breathe (teal), HALT Check (gold)
- **AI Money Coach** — Large prominent hero card opening the chat
- **Impulse Control Tools** — 2×2 grid: Cool Down Timer, If-Then Plans, 1-Second Rule, Exercises (CBT & ACT)
- **DNS Blocking** — Card shown only if not already set up
- All tools open as fullScreenCovers (same pattern as old ToolkitView)

### Hub Tab (new)
- All existing Games content: player command bar, live ticker, today's missions, game cards (Quests, Vault), weekly challenge, unified progress, leaderboard, stats dashboard
- **New "Spending Tools" section** at the bottom: Budget Tracker, Ghost Budget, Vibe Check in a 2×2 grid
- Navigation title: "Hub"

---

## Changes

### Files Modified
- **ContentView.swift** — Update AppTab enum (6 cases), update TabView with 6 tabs
- **GamesHubView.swift** — Rename struct to `HubView`, change nav title to "Hub", add spending tools section at bottom
- **ChallengesHubView.swift** — Rename struct to `PactsView`, rebrand all user-facing "Challenge" → "Pact", remove dismiss toolbar button
- **SplurjiMoodEngine.swift** — Update `.games` context references to `.hub`
- **PaywallView.swift** — "Unlimited Challenges" → "Unlimited Pacts"
- **ChallengeDetailView.swift** — User-facing "Challenge" strings → "Pact"
- **ChallengeCompletionView.swift** — "Challenge Complete!" → "Pact Complete!" etc.
- **ChallengeDetailView.swift** — "Challenge Calendar" → "Pact Calendar", "Leave Challenge" → "Leave Pact", alert text updates

### Files Created
- **Views/CoachTabView.swift** — New Coach tab with emergency tools, AI coach card, impulse control grid

### Files Deleted
- **Views/ToolkitView.swift** — All contents redistributed to CoachTabView and HubView

### String Renames (user-facing only)
- "Challenge" → "Pact" everywhere users see it
- "Games" → "Hub" in navigation title
- "Tools" → removed entirely
- Internal variable names, model classes, file names, and CloudKit record types stay unchanged

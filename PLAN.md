# Fix all 8 gaps from the PDF spec + Champion badge + Local notifications


## Overview
Address all 8 gaps identified between the PDF blueprint and the current implementation, add "Challenge Champion" badge to the profile, and add local notification placeholders for nudges/reactions/covers.

---

### **Fix 1: "At Risk" state trigger at 8 PM**
- Add a timer in the challenge detail screen that checks the current time
- If it's past 8 PM and the current user hasn't checked in today, automatically set their status to "atRisk"
- The yellow pulsing avatar ring already works — this just triggers the state change
- Sync the updated status to CloudKit

### **Fix 2: "Slipped" as a distinct status**
- When a user taps "I slipped" or midnight passes without check-in, set status to "slipped" (not just lose a life and stay "active")
- The "slipped" status persists for the rest of that day (red X on avatar)
- Update the lives engine: after processing a slip, set status to "slipped" instead of "active"
- Update the avatar ring logic and status labels to handle "slipped" distinctly (red ring + red X overlay)
- The next day's check-in resets them to "active"

### **Fix 3: Block nudges to shielded participants**
- In the participant row, hide the "Nudge" button when a participant's status is "shielded"
- Shielded participants are already protected — they just shouldn't receive nudge prompts

### **Fix 4: On Thin Ice — ice crystal avatar overlay**
- Replace the current small snowflake-on-red-circle with a more prominent ice crystal overlay on the avatar itself
- Use a frosted/icy visual treatment: semi-transparent ice overlay with a snowflake icon directly on the avatar circle

### **Fix 5: Local notifications for nudges, reactions, and covers**
- Request notification permission on app launch
- When a nudge is sent: schedule a local notification with text like "[emoji] [name] is checking on you! How's [challenge] going?"
- When a "Cheer On" is sent: "[emoji] [name] is cheering you on!"
- When a reaction is added: "[Name] reacted [emoji] to your check-in!"
- When someone covers a friend: "[Name] sent you a life!"
- These are local-only placeholders — real push notifications can be added later

### **Fix 6: Activity feed entries for spectator/leave/captain events**
- Add a new "activity event" type to the feed section
- When someone leaves: show "[Name] stepped back from the challenge. Their $[X] stays with us."
- When captain transfers: show "[Old captain] stepped back. [New captain] is now leading the challenge."
- These appear inline in the Recent Activity section alongside check-ins

### **Fix 7: "Challenge Champion" badge in profile**
- Add a new badge definition: name "Challenge Champion", category "Skill", description "Completed a Friend Challenge", icon "trophy.fill"
- When a challenge completes and the user's status becomes "completed", automatically award this badge
- The badge appears in their existing badge collection on their profile

### **Fix 8: Improved cover animation**
- Replace the simple scale+opacity shield animation with a path-based animation
- The shield icon starts at the giver's position, follows a curved arc, and lands on the receiver's avatar
- Add a gold particle trail effect behind the moving shield
- Spring animation on landing with a subtle glow

---

### Files that will be changed
- **Lives engine** — Update slip logic to set "slipped" status
- **Challenge detail screen** — At Risk timer, nudge guard for shielded, activity feed events, improved cover animation
- **Avatar display** — Slipped state red X, On Thin Ice ice crystal overlay
- **App entry point** — Request local notification permission
- **Notification helper** — New utility for scheduling local notifications
- **Badge definitions** — Add Challenge Champion badge
- **Challenge completion logic** — Award Champion badge on completion

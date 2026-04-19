# 545 — Household RBAC & Multi-User Permissions (Pro Tier)

**Epic:** Pro / Multi-User Households  
**Priority:** P3 (Future, M5+ — defer until we validate multi-user demand)  
**Size:** L (backend permissions model + sync + UI for role management)

---

## Context
Pro tier includes "household management" features (shared inventory, shopping lists, spending analytics). As multi-user households adopt the app, they may need different permission levels for different members.

**Use cases:**
- **Admin (primary user):** Full access to add/edit/delete items, manage spending, invite members
- **Member (spouse/roommate):** Add/edit items, mark consumed, view analytics
- **Viewer (child/guest):** View inventory, mark items consumed (no delete, no spending data)
- **Child-safe mode:** View-only + simplified UI (no spending, no waste analytics)

**Current state (M1-M4):**
- Single-user accounts (MVP)
- Pro tier allows household sharing, but all members have equal access
- No fine-grained permissions

**Problem:**
- Parents want to give kids access without allowing deletions
- Some users want view-only access for babysitters/houseguests
- Spending data may be sensitive in shared households
- No audit log for who added/deleted what

---

## Goal
Enable Pro-tier households to assign role-based permissions to members, providing granular control over inventory actions, spending visibility, and data management.

---

## Expected behavior

### Settings → Household Members (Pro Only)
```
👥 Household Members

Your Household (4 members)

You (Admin)
  Full access to all features
  [Manage]

Jane Doe (Member)
  Can add, edit, and mark items consumed
  [Edit Role]  [Remove]

Alex Doe (Viewer)
  View inventory, mark consumed only
  [Edit Role]  [Remove]

Guest (Child-Safe)
  View-only mode, simplified UI
  [Edit Role]  [Remove]

[+ Invite Member]
```

### Invite Flow
Tap "+ Invite Member" → show form:
```
Invite Household Member

Email or Phone: __________

Role:
○ Admin    — Full access (add, edit, delete, manage members)
○ Member   — Add, edit, mark consumed (no delete, no member mgmt)
○ Viewer   — View inventory, mark consumed (no edits, no delete)
○ Child    — View-only, simplified UI (no spending, no analytics)

[Send Invite]  [Cancel]
```

### Role Capabilities Matrix
| Action                  | Admin | Member | Viewer | Child |
|-------------------------|-------|--------|--------|-------|
| View inventory          | ✓     | ✓      | ✓      | ✓     |
| Add items               | ✓     | ✓      | ✗      | ✗     |
| Edit items              | ✓     | ✓      | ✗      | ✗     |
| Delete items            | ✓     | ✗      | ✗      | ✗     |
| Mark consumed/wasted    | ✓     | ✓      | ✓      | ✓     |
| View shopping list      | ✓     | ✓      | ✓      | ✗     |
| Edit shopping list      | ✓     | ✓      | ✗      | ✗     |
| View spending analytics | ✓     | ✓      | ✗      | ✗     |
| View waste analytics    | ✓     | ✓      | ✗      | ✗     |
| Manage members          | ✓     | ✗      | ✗      | ✗     |
| Export data             | ✓     | ✗      | ✗      | ✗     |

### Audit Log (Admin Only)
```
📜 Activity Log (Last 30 Days)

Jan 20, 2026 3:45pm
  Jane Doe deleted "Milk" from inventory

Jan 20, 2026 2:10pm
  You added "Apples" to inventory

Jan 19, 2026 8:30pm
  Alex Doe marked "Bread" as consumed
```

### Child-Safe Mode UI
When user logs in with "Child" role:
- **Simplified home screen:** Large icons, no spending data, no waste tracking
- **View-only inventory:** Can tap items to see details, but no edit/delete buttons
- **Mark consumed:** Single button "I ate this!" (no waste logging)
- **No shopping list access**
- **No settings access**

---

## Acceptance criteria (Definition of Done)

### Functional
- [ ] Pro users can invite household members via email/phone
- [ ] Admin can assign roles: Admin, Member, Viewer, Child
- [ ] Role permissions enforced on all actions (add/edit/delete/view)
- [ ] Admin can change member roles or remove members
- [ ] Member receives invite notification (email/SMS) with join link
- [ ] Audit log tracks who performed each action (add/edit/delete)
- [ ] Child-safe mode shows simplified, view-only UI

### Security
- [ ] Permissions checked server-side (not just UI-level)
- [ ] API endpoints return 403 Forbidden if user lacks permission
- [ ] Audit log immutable (no delete, only append)
- [ ] Invites expire after 7 days if not accepted

### Data Model
- [ ] `household` table: household_id, created_by, name
- [ ] `household_members` table: household_id, user_id, role, invited_at, accepted_at
- [ ] `activity_log` table: household_id, user_id, action, item_id, timestamp
- [ ] Roles enum: `admin`, `member`, `viewer`, `child`

### UX
- [ ] Settings → Household Members shows all members + roles
- [ ] Invite flow includes role picker with descriptions
- [ ] Role change shows confirmation modal ("Are you sure?")
- [ ] Admin can't remove themselves (must transfer admin first)
- [ ] Child-safe mode has bright, friendly UI (large icons, simple language)

### Telemetry
- [ ] Log `household_member_invited`, `household_member_joined`, `household_member_removed`, `role_changed`
- [ ] Track role distribution (how many households use Viewer/Child roles)
- [ ] Log permission denials (user attempted action they lack permission for)

### Offline-First
- [ ] Role cached locally (works offline for 7 days)
- [ ] Actions queue locally → sync when online
- [ ] Permission check fails gracefully offline (allow optimistic edits, reconcile on sync)

### Accessibility
- [ ] Role picker labels clear ("Admin: Full access to all features")
- [ ] Audit log navigable via keyboard
- [ ] Child-safe mode meets WCAG AA contrast requirements

---

## Out of scope
- Custom roles (only predefined: Admin/Member/Viewer/Child)
- Per-item permissions ("Jane can only edit Dairy items")
- Real-time collaboration (live updates when another user edits)
- Fine-grained spending visibility (e.g., "Jane can see her own spending only")
- Multi-household support (user in multiple households)

---

## Implementation notes

### Backend Architecture
1. **Household Service:**
   - `createHousehold(userId) → householdId`
   - `inviteMember(householdId, email, role) → inviteToken`
   - `acceptInvite(inviteToken, userId) → membership`
   - `removeMember(householdId, userId, adminUserId)`
   - `changeRole(householdId, userId, newRole, adminUserId)`

2. **Permissions Middleware:**
   - Every inventory/shopping API call checks `household_members.role`
   - Returns 403 if action not allowed for role
   - Example:
     ```python
     def require_permission(action):
         role = get_user_role(household_id, user_id)
         if role not in PERMISSIONS[action]:
             raise Forbidden("Insufficient permissions")
     ```

3. **Audit Log:**
   - Every mutation (add/edit/delete) writes to `activity_log`
   - Exposed via `/api/households/:id/activity` (admin only)

### Frontend UI
1. **Settings → Household Members:**
   - List of members with role badges
   - "+ Invite Member" → modal with email + role picker
   - Tap member → modal with "Edit Role" / "Remove" options

2. **Child-Safe Mode:**
   - Separate navigation flow (no bottom nav tabs)
   - Single screen: "My Food" with large item cards
   - Tap item → show details + "I ate this!" button
   - No add/edit/delete buttons rendered

3. **Permission Denied Feedback:**
   - If user taps delete button but lacks permission → toast: "You don't have permission to delete items. Ask an Admin."

### Edge Cases
- Admin removes themselves → show error: "Transfer admin role first"
- User tries to delete item while offline + lacks permission → allow optimistic delete, revert on sync if permission denied
- Invite email already in household → show error: "User already a member"
- Child role user taps Settings → redirect to simplified settings (name, profile pic only)

---

## Test plan

### Automated
- Unit test: permission check logic (all role + action combinations)
- Unit test: invite token generation + expiry
- API test: 403 response when user lacks permission
- API test: audit log writes on every mutation
- Integration test: invite flow (send invite → accept → verify role)
- Widget test: Settings household members list renders roles correctly
- Widget test: Child-safe mode hides restricted UI elements

### Manual
1. **Invite Flow (Admin):**
   - Invite member with "Member" role
   - Verify invite email sent
   - Accept invite → verify user joins household
   - Check Settings → Household Members → verify role shown

2. **Permission Enforcement:**
   - Log in as Member → try to delete item → verify toast: "You don't have permission"
   - Log in as Viewer → try to add item → verify "+ Add Item" button hidden
   - Log in as Admin → verify all actions allowed

3. **Role Change:**
   - Admin changes Member → Viewer
   - Member re-opens app → verify UI updates (no add/edit buttons)
   - Verify existing edits still work (optimistic cache)

4. **Audit Log:**
   - Admin views activity log
   - Verify all actions listed with user names + timestamps
   - Delete item as Admin → verify log entry appears

5. **Child-Safe Mode:**
   - Log in as Child → verify simplified UI
   - Tap item → tap "I ate this!" → verify marked consumed
   - Verify no access to Shopping List, Progress, Settings

6. **Offline:**
   - Go offline → try to delete item as Member
   - Verify optimistic delete
   - Go online → verify revert + toast: "Action not allowed"

---

## Dependencies
- **Blocked by:**
   - Issue #090 (Flutter skeleton + DI)
   - Issue #130 (Pro tier gating logic)
   - Issue #350 (Cloud sync + backend API)
   - Issue #360 (User accounts + authentication)

- **Blocks:**
   - None (this is a future enhancement)

---

## Related issues
- Issue #130: Pro tier feature gating
- Issue #350: Cloud sync (backend needed for multi-user)
- Issue #360: User accounts (authentication required)
- Issue #370: Subscription management (RBAC is Pro-only)

---

## Discussion points
1. **Defer to M5+:** RBAC is complex and adds significant dev/test overhead. Validate demand with simple shared access (all-or-nothing) in M3-M4 first.

2. **Alternative: Two-tier only:** Start with just "Admin" and "Member" (no Viewer/Child). Simpler to implement, covers 80% of use cases.

3. **Privacy concerns:** Some households may not want shared inventory (e.g., roommates with separate food). Consider "My Items" vs. "Shared Items" tagging.

4. **Audit log retention:** 30 days free, unlimited for Pro? Or always unlimited?

5. **Child-safe mode:** May need separate app or in-app parental controls (PIN lock).

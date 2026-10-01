# Save Trials Feature - End-to-End Testing Guide

## Phase 1 Implementation Status: ✅ COMPLETE

All core functionality has been implemented. This document guides you through testing the complete save trials feature.

---

## Pre-Test Setup

1. **Ensure the database migration ran successfully**
   ```bash
   bin/rails db:migrate
   # You should see: == 20260118073959 CreateSavedTrials: migrated
   ```

2. **Start the Rails server**
   ```bash
   bin/dev
   # or: rails s
   ```

3. **Open the application in your browser**
   ```
   http://localhost:3000
   ```

---

## Test Scenarios

### Test 1: Save a Trial from My Trials Detail Page

**Preconditions:**
- You are logged in
- Your profile is complete
- You are viewing a trial detail page from "My Trials" search

**Steps:**
1. Navigate to `GET /my_trials` (search for any condition/location)
2. Click on a trial title to view details
3. Look for the blue "Save Trial" button in the header (top right area)

**Expected Behavior:**
- ✅ Button is visible and clickable
- ✅ Button shows bookmark icon + "Save Trial" text
- ✅ Button is styled with gray border and light background

**Action:**
4. Click "Save Trial" button

**Expected Behavior:**
- ✅ Button immediately changes to blue background
- ✅ Button text changes to "Saved ✓"
- ✅ Bookmark icon fills with solid color
- ✅ Green notification appears: "Trial saved successfully!"
- ✅ No page reload occurs (AJAX request)

**Verification:**
- Check browser console (F12) - no JavaScript errors
- Check Network tab - POST request to `/saved_trials` should return 201 status

---

### Test 2: Save a Trial from Public Search

**Preconditions:**
- You are logged in
- You are viewing a trial detail page from "Public Search" (unauthenticated search)

**Steps:**
1. Navigate to `GET /search`
2. Search for any trial (no authentication needed for search)
3. Click on a trial from results
4. Look for "Save Trial" button

**Expected Behavior:**
- ✅ Button is visible and clickable (since you're now authenticated viewing this detail)
- ✅ Same save functionality as Test 1

---

### Test 3: View Saved Trials List

**Preconditions:**
- You have saved at least 1 trial from previous tests

**Steps:**
1. Navigate to `/saved_trials`

**Expected Behavior:**
- ✅ Page loads with header "Saved Trials"
- ✅ Filter/search form is visible at top
- ✅ Your saved trial appears in the list
- ✅ Trial card shows:
  - Trial title (should be a link)
  - NCT ID
  - "Saved X minutes ago"
  - Status badge (blue "interested")
  - Edit and Remove buttons

---

### Test 4: Filter Saved Trials by Status

**Preconditions:**
- You have at least 1 saved trial

**Steps:**
1. On `/saved_trials` page
2. Find the "Status" dropdown in the filter form
3. Select a different status like "applying" or "contacted"
4. Submit the form

**Expected Behavior:**
- ✅ URL updates with `?status=applying`
- ✅ List updates (if no trials with that status, empty state shows)
- ✅ Filter controls retain selected value

---

### Test 5: Search Saved Trials

**Preconditions:**
- You have at least 1 saved trial

**Steps:**
1. On `/saved_trials` page
2. Type trial title or part of it in the search box
3. Click "Search" button

**Expected Behavior:**
- ✅ URL updates with `?search=query`
- ✅ List filters to matching trials
- ✅ Searches in both trial_title and notes fields
- ✅ Case-insensitive search works

---

### Test 6: Sort Saved Trials

**Preconditions:**
- You have at least 2-3 saved trials

**Steps:**
1. On `/saved_trials` page
2. Select "Status" from "Sort By" dropdown
3. Keep "Newest First" selected
4. Submit form

**Expected Behavior:**
- ✅ Trials sort by status field
- ✅ URL updates with `?sort_by=status&sort=newest`
- ✅ List re-orders

**Steps (continued):**
5. Change to "Oldest First"
6. Submit form

**Expected Behavior:**
- ✅ Sort order reverses
- ✅ URL updates with `?sort=oldest`

---

### Test 7: View Saved Trial Detail

**Preconditions:**
- You have saved at least 1 trial

**Steps:**
1. On `/saved_trials` list page
2. Click on trial title

**Expected Behavior:**
- ✅ Navigates to `/saved_trials/:id` (e.g., `/saved_trials/42`)
- ✅ Page shows:
  - Trial title
  - Status card (showing current status)
  - Notes section (empty if no notes yet)
  - Tags section (empty if no tags yet)
  - Sidebar with save date, match score, action buttons
- ✅ All edit buttons link to modal/edit form

---

### Test 8: Edit Saved Trial Metadata

**Preconditions:**
- You are viewing a saved trial detail page

**Steps:**
1. Click "Edit" button next to Status
2. Look for a modal/form to open

**Expected Behavior:**
- ✅ Modal or form opens with title "Edit Saved Trial"
- ✅ Form includes fields:
  - Status dropdown (pre-filled with current value)
  - Notes textarea (pre-filled)
  - Tags input (pre-filled)
  - Match score display (read-only)
- ✅ Save and Cancel buttons visible

**Steps (continued):**
3. Change status to "applying"
4. Add a note: "This looks promising, good location"
5. Add tags: "nearby, promising"
6. Click "Save Changes"

**Expected Behavior:**
- ✅ Form submits via AJAX (no page reload)
- ✅ Modal closes
- ✅ Page/card updates with new values
- ✅ Success notification appears
- ✅ Database record updated (can verify by refreshing page)

---

### Test 9: Update Match Score (if available)

**Preconditions:**
- You saved a trial from "My Trials" personalized search
- Trial should have match_score value

**Steps:**
1. Navigate to the saved trial's detail page
2. Open edit modal
3. Look for match score field

**Expected Behavior:**
- ✅ Match score displays as read-only value
- ✅ Cannot modify it from the form
- ✅ Shows percentage and "Match percentage from your last search" text

---

### Test 10: Delete a Saved Trial

**Preconditions:**
- You are on the saved trials list
- You have at least 1 saved trial

**Steps:**
1. Find a trial in the list
2. Click "Remove" button

**Expected Behavior:**
- ✅ Confirmation dialog appears
- ✅ Asking "Are you sure?"

**Steps (continued):**
3. Confirm deletion

**Expected Behavior:**
- ✅ Trial removed from list (no page reload, if using Turbo Streams)
- ✅ Or page reloads and trial is gone
- ✅ No error messages
- ✅ Database verified: trial no longer exists for that user

---

### Test 11: Unsave a Trial from Detail View

**Preconditions:**
- You are viewing a saved trial detail page
- Trial is currently saved

**Steps:**
1. Look for "Remove from Saved" button in sidebar
2. Click it

**Expected Behavior:**
- ✅ Trial is removed
- ✅ Redirect back to `/saved_trials` list
- ✅ Trial no longer appears in list

---

### Test 12: Button State Persistence

**Preconditions:**
- You saved a trial and are on the trial detail page

**Steps:**
1. The "Save Trial" button should show "Saved ✓" state
2. Refresh the page (F5 or Cmd+R)

**Expected Behavior:**
- ✅ Button still shows "Saved ✓" state
- ✅ State persists across page reloads (server-side check)

**Steps (continued):**
3. Click "Save Trial" button to unsave

**Expected Behavior:**
- ✅ Button changes back to "Save Trial" gray state
- ✅ Refresh page

**Expected Behavior:**
- ✅ Button shows "Save Trial" (unsaved state)

---

### Test 13: Authorization - Can't Access Other User's Trials

**Preconditions:**
- You have 2 user accounts (or know another user's trial ID)

**Steps:**
1. Log in as User A
2. Save a trial, note the ID (e.g., saved trial #42)
3. Log out
4. Log in as User B
5. Try to access `/saved_trials/42` directly via URL

**Expected Behavior:**
- ✅ Error 403 (Forbidden) or redirected (depending on Pundit configuration)
- ✅ Cannot view/edit/delete another user's saved trials

---

### Test 14: Pagination

**Preconditions:**
- You have saved 20+ trials (or manually create fixtures)

**Steps:**
1. Navigate to `/saved_trials`
2. Page should show 20 trials per page
3. Pagination controls appear at bottom
4. Click "Next" or page 2

**Expected Behavior:**
- ✅ Shows next 20 trials
- ✅ URL updates with `?page=2`
- ✅ Pagination controls show current page highlighted
- ✅ "Previous" button appears on page 2+

---

### Test 15: Combined Filters and Sort

**Preconditions:**
- You have multiple saved trials with different statuses

**Steps:**
1. On `/saved_trials` page
2. Select Status = "applying"
3. Select Sort By = "status"
4. Select Sort = "oldest"
5. Enter search query
6. Submit form

**Expected Behavior:**
- ✅ URL has all query params: `?status=applying&sort_by=status&sort=oldest&search=query`
- ✅ Results filtered and sorted correctly
- ✅ All filter controls retain their values after submit

---

### Test 16: Empty State

**Preconditions:**
- You have no saved trials (clear them or use new account)

**Steps:**
1. Navigate to `/saved_trials`

**Expected Behavior:**
- ✅ Empty state message appears
- ✅ "No saved trials yet" with description
- ✅ "Search Trials" button link to my_trials
- ✅ No errors, graceful UI

---

### Test 17: Mobile Responsiveness

**Preconditions:**
- Any saved trial page

**Steps:**
1. Open browser DevTools (F12)
2. Toggle Device Toolbar (Cmd+Shift+M on Mac, or button in DevTools)
3. Select "iPhone 12" or similar

**Expected Behavior:**
- ✅ Save button displays correctly on mobile
- ✅ Filter form stacks vertically
- ✅ Trial cards are readable
- ✅ No horizontal scrolling
- ✅ Buttons are touch-friendly size

---

### Test 18: Tags Functionality

**Preconditions:**
- You are editing a saved trial

**Steps:**
1. Open edit modal
2. In Tags field, enter: "promising, nearby, hospital-downtown"
3. Save

**Expected Behavior:**
- ✅ Tags save correctly
- ✅ Commas properly separate tags
- ✅ Whitespace trimmed

**Steps (continued):**
4. View saved trial detail page
5. Look at tags section

**Expected Behavior:**
- ✅ Tags display as individual chips/badges
- ✅ Each tag is: "promising", "nearby", "hospital-downtown"
- ✅ Each has a distinct visual appearance (blue background, pill shape)

---

### Test 19: Notes with Special Characters

**Preconditions:**
- You are editing a saved trial

**Steps:**
1. Open edit modal
2. Enter notes with special characters and formatting:
   ```
   This trial looks great! 
   Location: Downtown Hospital
   Cost: ~$500
   Contact: Dr. Smith (555-1234)
   ```
3. Save

**Expected Behavior:**
- ✅ All characters save correctly
- ✅ No encoding errors
- ✅ Newlines preserved
- ✅ Special characters (!, @, #, $, %, etc.) work fine

---

### Test 20: Bulk Selection (UI Ready - Logic Optional)

**Preconditions:**
- You have 3+ saved trials
- You are on the saved trials list

**Steps:**
1. Look for "Select All" checkbox at top of list
2. Check the checkbox

**Expected Behavior:**
- ✅ All trial checkboxes become checked
- ✅ "Bulk actions" panel appears/shows
- ✅ Status dropdown and "Update" button visible

**Steps (continued):**
3. Select a status from bulk actions dropdown
4. Click "Update"

**Expected Behavior:**
- ⚠️ If not implemented: Nothing happens (expected for Phase 1)
- ✅ If implemented: All checked trials update to selected status

---

## Browser Compatibility Testing

Test on:
- ✅ Chrome (latest)
- ✅ Firefox (latest)
- ✅ Safari (latest)
- ✅ Mobile Safari (iOS)
- ✅ Chrome Mobile (Android)

---

## Performance Testing

1. **Response Times**
   - Saving a trial should take < 1 second
   - Loading `/saved_trials` with 20 trials should take < 500ms
   - Search should return results in < 500ms

2. **Load Testing**
   - With 100+ saved trials, list should still load quickly
   - Pagination prevents loading too much data at once

3. **Database Queries**
   - Open Rails console and check query counts
   - Should use indexes on (user_id, nct_id), status, created_at

---

## Error Handling Testing

### Test: Save Duplicate Trial
1. Save the same trial twice
2. **Expected**: Error message "already saved by this user"

### Test: Invalid Status Value
1. Manually craft request with invalid status
2. **Expected**: Error message, form re-renders with error

### Test: Missing Required Fields
1. Try to save without nct_id
2. **Expected**: Validation error

### Test: Network Error
1. Disable internet while saving
2. **Expected**: Error notification "An error occurred while saving"

### Test: Session Timeout
1. Let session expire, then try to save
2. **Expected**: Redirected to login page or 401 error

---

## Database Verification Checklist

After running all tests, verify in Rails console:

```ruby
# Check saved trials table
SavedTrial.count  # Should be > 0 after tests

# Check specific user's trials
user = User.first
user.saved_trials.count

# Check unique constraint works
user.saved_trials.where(nct_id: "NCT12345678").count  # Should be <= 1

# Check indexes exist
SavedTrial.connection.indexes(:saved_trials).map(&:name)
# Should include: index_saved_trials_on_user_and_nct, index_saved_trials_on_status, index_saved_trials_on_created_at

# Check all statuses present
SavedTrial.pluck(:status).uniq.sort
# Should match SavedTrial::STATUSES
```

---

## Troubleshooting During Testing

| Issue | Solution |
|-------|----------|
| Save button not appearing | Ensure you're logged in and viewing a trial detail page |
| "JavaScript error" in console | Check browser console (F12), look for actual error message |
| Saved trial not appearing in list | Try refreshing page, check URL filters/search |
| 403 Forbidden on another user's trial | Expected! Authorization is working correctly |
| Edit modal won't open | Check browser console, ensure Stimulus controller loaded |
| Pagination links don't work | Check URL params are preserved in links |
| Tags not saving | Check for very long tags, special characters |

---

## Sign-Off Checklist

- [ ] All 20 test scenarios pass
- [ ] No JavaScript errors in browser console
- [ ] No Rails errors in server console
- [ ] Mobile responsive (tested on 2+ devices)
- [ ] Authorization works (can't access other users' trials)
- [ ] Database has correct data and indexes
- [ ] Performance acceptable (< 1s for most operations)
- [ ] Empty states display correctly
- [ ] Special characters and edge cases handled

---

## Known Limitations (Phase 1)

- ⚠️ Tag autocomplete: Not yet implemented (manual comma entry only)
- ⚠️ Bulk update: UI present but backend logic not implemented
- ⚠️ Match score: Only populated when saved from personalized search
- ⚠️ Notifications: Email/SMS not implemented
- ⚠️ Export: CSV export not yet available
- ⚠️ Trial comparison: Not available yet

---

## Next Phase Items

- [ ] Implement tag autocomplete
- [ ] Complete bulk update logic
- [ ] Add nav link to saved trials in header
- [ ] Admin dashboard stats on most-saved trials
- [ ] Export saved trials to CSV
- [ ] Notifications on trial status updates
- [ ] Trial comparison tool
- [ ] Share saved trials with caregiver

---

## Questions or Issues?

If you encounter any issues during testing:

1. Check browser console for JavaScript errors
2. Check Rails server console for errors
3. Check database for records using Rails console
4. Review the implementation files:
   - `app/models/saved_trial.rb`
   - `app/controllers/saved_trials_controller.rb`
   - `app/javascript/controllers/save_trial_controller.js`

---

**Status**: ✅ Ready for testing

**Date Completed**: 2026-01-18

**Implementation Version**: Phase 1 (Core Functionality)

**Next Review**: After phase 1 testing complete


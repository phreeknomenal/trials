# Save Trials Feature - Implementation Summary

## Phase 1: Core Save Functionality ✅ COMPLETE

### What Was Built

#### 1. **Database Layer**
- **Migration**: `db/migrate/20260118073959_create_saved_trials.rb`
  - `saved_trials` table with user_id, nct_id, trial_title, notes, tags, status, match_score
  - Unique constraint on (user_id, nct_id) to prevent duplicate saves
  - Indexes on: user_id, status, created_at for efficient querying
  - Default status: "interested"

#### 2. **Model Layer** 
- **SavedTrial** (`app/models/saved_trial.rb`)
  - Belongs to User (validates presence, uniqueness per user)
  - Status enum with 7 states: interested, applying, contacted, enrolled, rejected, completed, not_eligible
  - Tag management helpers: `tags_array`, `add_tag()`, `remove_tag()`
  - Full validation suite

- **User** (`app/models/user.rb`)
  - Added: `has_many :saved_trials, dependent: :destroy`

#### 3. **Authorization**
- **SavedTrialPolicy** (`app/policies/saved_trial_policy.rb`)
  - Users can only view/edit/delete their own saved trials
  - Policy scope ensures users only see their saved trials in lists

#### 4. **Controller**
- **SavedTrialsController** (`app/controllers/saved_trials_controller.rb`)
  - **index**: List all saved trials with filtering, searching, sorting, pagination
    - Filter by status
    - Search in trial_title and notes (case-insensitive)
    - Sort by date, status, or match_score
    - Paginated with Pagy (20 per page)
  - **show**: Detail view of a single saved trial
  - **create**: Save a new trial (via AJAX)
  - **edit**: Load edit modal form (HTML partial)
  - **update**: Update notes, tags, status, match_score
  - **destroy**: Remove a saved trial

#### 5. **Frontend Components**

##### Save Trial Button Component
- **Component**: `app/components/buttons/save_trial_button_component.rb`
- **Template**: `app/components/buttons/save_trial_button_component.html.erb`
- Features:
  - Toggles between "Save Trial" / "Saved ✓" states
  - Visual feedback with color changes (blue when saved)
  - Bookmarkicon variations
  - Configurable sizing (sm, md, lg)
  - Ready to be dropped into trial detail pages

##### Stimulus Controllers
1. **SaveTrialController** (`app/javascript/controllers/save_trial_controller.js`)
   - Handles save/unsave toggle
   - Fetches trial data and POSTs to create saved_trial
   - Updates button state dynamically
   - Shows success/error notifications
   - Persists state via data attributes

2. **SavedTrialModalController** (`app/javascript/controllers/saved_trial_modal_controller.js`)
   - Opens/closes edit modal
   - Loads form via AJAX
   - Handles form submission

#### 6. **Views**

##### Saved Trials List (`app/views/saved_trials/index.html.erb`)
- Search bar with trial title/notes search
- Filter panel:
  - Status filter (dropdown)
  - Sort by (date, status, match score)
  - Sort order (newest/oldest first)
- Bulk action selection for updating multiple trials
- Trial cards showing:
  - Title (linked to trial detail)
  - NCT ID with copy-friendly formatting
  - Save date (relative time)
  - Match score (if available)
  - Status badge with color coding
  - Tags as chips
  - Notes preview
  - Quick actions (Edit, Remove)
- Pagination with numbered page links
- Empty state when no trials saved

##### Saved Trial Detail (`app/views/saved_trials/show.html.erb`)
- Three-column layout (2-col content, 1-col sidebar)
- Status card with change link
- Notes section with edit link
- Tags section with edit link
- Sidebar with:
  - Save date
  - Match score
  - "View Full Trial" link (goes to trial detail)
  - "Remove from Saved" button

##### Edit Modal (`app/views/saved_trials/_edit_modal.html.erb`)
- Status dropdown
- Notes textarea (Markdown support mentioned)
- Tags input (comma-separated)
- Match score display (read-only)
- Save/Cancel buttons

##### Pagination Partial (`app/views/saved_trials/_pagination.html.erb`)
- Numbered page links
- Previous/Next navigation
- Preserves search/filter params

#### 7. **Routes**
```ruby
resources :saved_trials, only: [ :index, :show, :edit, :create, :update, :destroy ]
```

#### 8. **Helper Methods**
- **ApplicationHelper**: `status_badge_classes(status)` - returns Tailwind classes for status colors

### Data Flow

#### Saving a Trial
1. User clicks "Save Trial" button on trial detail page
2. SaveTrialController captures nct_id, trial_title
3. POSTs to `POST /saved_trials`
4. SavedTrialsController creates SavedTrial record
5. Button updates to "Saved ✓" with blue styling
6. Success notification appears

#### Viewing Saved Trials
1. User navigates to `GET /saved_trials`
2. SavedTrialsController fetches user's saved trials (Pundit scoped)
3. Applies filters, search, sort
4. Renders list with all metadata

#### Editing a Trial's Metadata
1. User clicks "Edit" button
2. SavedTrialModalController loads edit modal form
3. User updates status/notes/tags
4. Form submission PATCHes to `PATCH /saved_trials/:id`
5. SavedTrialsController updates record
6. Modal closes, user returns to list or detail page

#### Removing a Trial
1. User clicks "Remove" button
2. Deletes from `DELETE /saved_trials/:id`
3. Record removed from database
4. List/detail page updates

### What's Ready for Next Phase

- ✅ Core save/unsave/edit functionality
- ✅ Status tracking with 7 states
- ✅ Notes and tags with autocomplete foundation
- ✅ Match score persistence
- ✅ Full filtering, searching, sorting
- ✅ Bulk status updates (UI ready, backend logic needed)
- ✅ Pundit authorization
- ✅ Beautiful UI with Tailwind

### What Still Needs Implementation (Phase 2/3)

1. **Add Save Button to Trial Detail Pages**
   - Import SaveTrialButtonComponent into my_trials/show and search/show views
   - Pass current trial data and check if it's already saved
   - Integrate with SaveTrialController

2. **Bulk Actions Completion**
   - JavaScript to handle bulk checkbox selection
   - Bulk update endpoint (or iterate with PATCH)

3. **Tag Autocomplete**
   - Create autocomplete library integration (e.g., Trix or Alpine)
   - Suggest user's existing tags as they type

4. **Role-Based Variations**
   - Determine if employees/admins need special views
   - Add role checks in views/controller

5. **Advanced Features**
   - Export saved trials to CSV
   - Share saved trials list with caregivers
   - Trial comparison (side-by-side)
   - Mobile optimization tweaks
   - Notifications on trial updates

### Database Schema

```
saved_trials
├── id (PK)
├── user_id (FK) → users.id
├── nct_id (string, not null) - clinicaltrials.gov ID
├── trial_title (string) - cached for display
├── notes (text) - user's personal notes
├── tags (string) - comma-separated
├── status (string, default: "interested") - enum value
├── match_score (decimal 5,2) - from last search
├── created_at (timestamp)
├── updated_at (timestamp)

Indexes:
├── user_id (FK)
├── (user_id, nct_id) UNIQUE - prevents duplicate saves
├── status - for filtering
├── created_at - for sorting
```

### Testing Checklist

- [ ] Create a saved trial via button (full flow)
- [ ] View saved trials list (index page loads)
- [ ] Filter by status (shows only selected status)
- [ ] Search by title (finds matching trial)
- [ ] Sort by date/status/match (ordering works)
- [ ] Edit status/notes/tags (updates persist)
- [ ] Delete a saved trial (removed from DB and UI)
- [ ] Pagination (navigate between pages)
- [ ] Unauthorized access (user can't see another user's trials)
- [ ] Bulk select and update (if implemented)

---

## Next Steps

1. **Integrate Save Button** into existing trial detail pages
   - Update `app/views/my_trials/show.html.erb`
   - Update `app/views/search/show.html.erb`
   - Check if trial is already saved and pass saved_trial record

2. **Test End-to-End** (Phase 12)
   - Manually test full save/edit/delete flow
   - Verify authorization works
   - Test filtering/sorting

3. **Add to Navigation** (if needed)
   - Add link to "Saved Trials" in main navigation
   - Maybe add badge showing count of saved trials

4. **Polish & Deploy**
   - Handle edge cases
   - Add error boundaries
   - Test on mobile
   - Deploy to staging


# Save Trials Feature - Integration Guide

## Quick Start: Adding the Save Button to Trial Pages

### Step 1: Find Your Trial Detail View
Locate the trial detail page template (likely one of these):
- `app/views/my_trials/show.html.erb`
- `app/views/search/show.html.erb`

### Step 2: Get Trial Data and Check if Saved

Add this to your trial detail controller action (e.g., `my_trials_controller.rb`):

```ruby
def show
  # ... existing code ...
  
  # Check if trial is already saved
  @saved_trial = current_user.saved_trials.find_by(nct_id: @trial_nct_id)
end
```

Or in a simpler way, just pass it from the view:

```erb
<% saved_trial = current_user.saved_trials.find_by(nct_id: @trial["protocolSection"]["identificationModule"]["nctId"]) %>
```

### Step 3: Add the Save Button Component to Your View

In your `my_trials/show.html.erb` or `search/show.html.erb`:

```erb
<!-- Somewhere near the top or in an actions section -->
<div class="my-4">
  <%= render SaveTrialButtonComponent.new(trial: @trial, saved_trial: @saved_trial) %>
</div>
```

### Step 4: Make Sure Stimulus is Initialized

The save button uses the `SaveTrialController` stimulus controller. Verify that:

1. Your layout includes Stimulus: `<%= javascript_include_tag "application", "data-turbo-track": "reload" %>`
2. The controller file exists: `app/javascript/controllers/save_trial_controller.js` ✅
3. Controllers are auto-loaded (default in Rails 8)

### Step 5: Test It

1. Navigate to a trial detail page
2. Click "Save Trial" button
3. Button should turn blue and say "Saved ✓"
4. Navigate to `/saved_trials` to see your saved trial
5. Try editing, filtering, searching

---

## Component API Reference

### SaveTrialButtonComponent

```ruby
<%= render SaveTrialButtonComponent.new(
  trial: @trial_data,           # Required: full trial object from API
  saved_trial: @saved_trial,    # Optional: SavedTrial record if already saved
  size: "md"                    # Optional: "sm" | "md" | "lg"
) %>
```

**Parameters:**
- `trial`: The trial object from clinicaltrials.gov API (expects JSON structure with protocolSection)
- `saved_trial`: If present and not nil, button renders as "Saved ✓" (blue state)
- `size`: Button size - "sm" (small), "md" (default), "lg" (large)

**Output:**
- Renders a button with save/unsave toggle functionality
- Automatically makes AJAX requests to save/delete
- Shows success/error notifications
- Styled with Tailwind CSS

---

## File Structure Reference

```
app/
├── components/buttons/
│   ├── save_trial_button_component.rb
│   └── save_trial_button_component.html.erb
├── controllers/
│   └── saved_trials_controller.rb
├── javascript/controllers/
│   ├── save_trial_controller.js
│   └── saved_trial_modal_controller.js
├── models/
│   └── saved_trial.rb
├── policies/
│   └── saved_trial_policy.rb
├── views/saved_trials/
│   ├── index.html.erb          # List all saved trials
│   ├── show.html.erb           # Detail view
│   ├── _edit_modal.html.erb    # Edit modal form
│   └── _pagination.html.erb    # Pagination controls
└── helpers/
    └── application_helper.rb   # status_badge_classes helper
```

---

## Endpoints Reference

### List Saved Trials
```
GET /saved_trials
GET /saved_trials?status=applying
GET /saved_trials?search=cancer
GET /saved_trials?sort_by=status&sort=oldest
GET /saved_trials?page=2
```

### Save a Trial
```
POST /saved_trials
Content-Type: application/x-www-form-urlencoded

saved_trial[nct_id]=NCT12345678
saved_trial[trial_title]=Example Trial Name
```

### Get Trial Detail
```
GET /saved_trials/:id
```

### Edit a Trial
```
GET /saved_trials/:id/edit        # Returns edit modal HTML

PATCH /saved_trials/:id
Content-Type: application/x-www-form-urlencoded

saved_trial[status]=applying
saved_trial[notes]=My notes here
saved_trial[tags]=promising, nearby
```

### Remove a Trial
```
DELETE /saved_trials/:id
```

---

## Styling & Customization

### Status Badge Colors
The status badges use these Tailwind classes:
```ruby
"interested"    => "bg-blue-100 text-blue-800"      # Blue
"applying"      => "bg-yellow-100 text-yellow-800"  # Yellow
"contacted"     => "bg-purple-100 text-purple-800"  # Purple
"enrolled"      => "bg-green-100 text-green-800"    # Green
"rejected"      => "bg-red-100 text-red-800"        # Red
"completed"     => "bg-gray-100 text-gray-800"      # Gray
"not_eligible"  => "bg-orange-100 text-orange-800"  # Orange
```

To customize, edit `app/helpers/application_helper.rb` → `status_badge_classes()` method

### Button Styling
The save button uses Tailwind CSS. To customize:
- Edit `app/components/buttons/save_trial_button_component.rb`
- Modify the `button_classes` method
- Update the SVG icons in the ERB template

---

## Known Limitations (Phase 1)

- ❌ Tag autocomplete not yet implemented (add Stimulus/Alpine control later)
- ❌ Bulk update functionality - UI ready but backend not implemented
- ❌ Match score only shows if saved during personalized search (not retroactively added)
- ❌ No email/SMS notifications on trial status changes
- ❌ No export functionality
- ❌ No trial comparison tool

---

## Troubleshooting

### Button Not Appearing
- Verify component is imported: `<%= render SaveTrialButtonComponent.new(...) %>`
- Check browser console for JavaScript errors
- Ensure trial data structure has `protocolSection.identificationModule.nctId`

### Save Not Working
- Open browser console to see error messages
- Check that user is authenticated (should be for my_trials)
- Verify CSRF token is present in `<meta name="csrf-token">`

### Modal Not Opening
- Check that `SavedTrialModalController` is loaded
- Verify data-action attributes are correct
- Check browser console for JavaScript errors

### Filters Not Working
- Use URL params: `?status=applying&search=cancer`
- Form should POST with method=get

---

## Next Integration Tasks

1. ✅ **Model & Controller** - DONE
2. ✅ **Button Component** - DONE  
3. ⏳ **Integrate into my_trials/show** - TO DO
4. ⏳ **Integrate into search/show** - TO DO
5. ⏳ **Add nav link to Saved Trials** - TO DO
6. ⏳ **Test end-to-end** - TO DO

See `scratch/SAVE_TRIALS_IMPLEMENTATION.md` for complete implementation details.


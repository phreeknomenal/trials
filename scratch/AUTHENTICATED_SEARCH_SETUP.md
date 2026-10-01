# Authenticated Search Setup

This document describes the authenticated search feature that was set up to provide a personalized clinical trial search experience for onboarded users.

## Overview

The application now has two separate search experiences:

1. **Public Search** (`/search`) - Open to all users (authenticated or not)
2. **Authenticated Search** (`/my_trials`) - Restricted to authenticated users with profiles

## Changes Made

### 1. MyTrialsController (`app/controllers/my_trials_controller.rb`)

Created a new controller for authenticated users that:
- Requires user authentication (`before_action :authenticate_user!`)
- Ensures users have created a profile before accessing
- Auto-populates search with user's profile data:
  - Default condition from user's profile conditions
  - Default location from user's profile city/state
- Supports the same search functionality as public search but personalized

### 2. Views

#### `app/views/my_trials/index.html.erb`
- Personalized search page with profile information displayed
- Shows user's conditions, location, and age
- Pre-fills search form with profile data
- Provides links to update profile
- Auto-searches using profile conditions if no search params provided

#### `app/views/my_trials/show.html.erb`
- Individual trial detail page for authenticated users
- Shows user's profile information in sidebar for easy reference
- Links back to "My Trial Search" instead of public search

### 3. Navigation Updates

#### `app/components/layout/navigation/menu/header_menu_component.rb`
Updated to show different navigation options based on authentication status:

**Authenticated Users:**
- "My Trial Search" → `/my_trials`
- "Browse All Trials" → `/search`

**Unauthenticated Users:**
- "Search Trials" → `/search`

### 4. Component Updates

#### `app/components/page/cards/study_card_component.rb`
- Added `base_path` parameter (defaults to `:search`)
- New `detail_path` method that generates correct links based on context
- Supports both public search and authenticated search paths

#### `app/components/page/cards/study_card_component.html.erb`
- Updated to use `detail_path` instead of hardcoded `search_path`
- Works correctly in both public and authenticated contexts

### 5. Helper Methods

#### `app/helpers/application_helper.rb`
Added `user_onboarded?` helper method for checking if a user is authenticated and has completed onboarding.

## Routes

```
GET /search          → search#index (public)
GET /search/:id      → search#show (public)
GET /my_trials       → my_trials#index (authenticated)
GET /my_trials/:id   → my_trials#show (authenticated)
```

## User Flow

### For Unauthenticated Users
1. Access public search at `/search`
2. Manually enter condition and location
3. Browse results
4. View individual trial details

### For Authenticated/Onboarded Users
1. Access personalized search at `/my_trials`
2. See profile information displayed (conditions, location, age)
3. Search form pre-populated with profile data
4. Automatically searches with first profile condition if no params provided
5. Can still manually adjust search parameters
6. View results with profile context
7. Can also access public search via "Browse All Trials" link

## Benefits

1. **Personalization**: Onboarded users get search results tailored to their health profile
2. **Convenience**: Auto-populated search fields save time
3. **Context**: Users can see their profile information while browsing trials
4. **Flexibility**: Authenticated users can still access public search if desired
5. **Security**: Requires authentication, ensuring only registered users access personalized features

## Profile Data Used for Personalization

- **Conditions**: First condition used as default search term
- **Location**: City and state used as default location filter
- **Age**: Displayed for reference when reviewing eligibility
- **Sex**: Displayed for reference when reviewing eligibility
- **Travel Preferences**: Displayed in profile context (can be used for future filtering)

## Trial Score Feature

### Overview
The trial score feature calculates a compatibility/match score between a user's profile and each clinical trial's eligibility criteria. Scores range from 0-100% and are categorized as:
- **Excellent** (80-100%): High compatibility
- **Good** (60-79%): Good compatibility
- **Fair** (40-59%): Moderate compatibility
- **Poor** (0-39%): Low compatibility

### Scoring Algorithm

The score is calculated using weighted criteria:

| Criterion | Weight | Description |
|-----------|--------|-------------|
| Age | 20% | Match between profile age and trial age requirements |
| Sex | 20% | Match between profile sex and trial sex requirements |
| Conditions | 25% | Overlap between profile conditions and trial conditions |
| Location | 15% | Proximity to trial locations |
| Study Type | 10% | Match with trial type preference (interventional/observational) |
| Phase/Risk | 10% | Alignment with user's risk tolerance |

### Implementation

**Service Class**: `app/services/trial_scorer.rb`
- Encapsulates all scoring logic
- Returns overall score, breakdown by criterion, and match level

**Controller Integration**: `MyTrialsController`
- Calculates scores for search results (`@studies_with_scores`)
- Calculates score for detail view (`@trial_score`, `@score_breakdown`, `@match_level`)
- Supports sorting by score via `?sort_by=score` parameter

**UI Components**:
- **Study Card**: Displays match score badge with color coding
- **Detail View Sidebar**: Shows comprehensive score breakdown with individual criterion scores
- **Sort Controls**: Toggle between sorting by score or relevance

**Helper Methods**: `application_helper.rb`
- `match_score_bg_class(match_level)`: Background color based on score level
- `match_score_border_class(match_level)`: Border color based on score level
- `match_score_text_class(match_level)`: Text color based on score level

### User Experience

1. **Search Results**: Each trial card shows a colored match score badge
2. **Sorting**: Users can sort results by match score or relevance
3. **Detail View**: Sidebar shows overall score with detailed breakdown
4. **Color Coding**:
   - Green: Excellent match
   - Blue: Good match
   - Yellow: Fair match
   - Gray: Poor match

### Future Enhancements

Potential improvements that could be added:

1. **Saved Trials**: Allow users to bookmark/save trials for later
2. **Geographic Distance**: Use geocoding API to calculate actual distance to trial sites
3. **Advanced Filtering**: Filter trials by minimum match score threshold
4. **Email Alerts**: Notify users of new trials matching their profile
5. **Application Tracking**: Track which trials users have applied to
6. **Notes**: Allow users to add private notes to trials
7. **Comparison**: Side-by-side comparison of multiple trials
8. **ML Scoring**: Train model on successful enrollments to improve scoring
9. **Custom Weights**: Let users adjust scoring weights based on priorities
10. **Exclusion Criteria Parsing**: Parse trial exclusion criteria with NLP

## Bug Fixes

### Pagination API Token Issue (Fixed)
**Problem:** The ClinicalTrials.gov API v2 uses opaque page tokens (not page numbers) for pagination. The original implementation was sending page numbers (1, 2, 3) as `pageToken`, causing a 400 "Incorrect pageToken format" error.

**Solution:** 
- **Changed API signature**: `ClinicalTrialClient.advanced_search` now accepts `page_token:` instead of `page:`
- **Session-based token storage**: Page tokens are stored in the user's session, mapped to page numbers
  - Allows standard "Previous / Page X / Next" pagination UI
  - Tokens are keyed by search parameters (condition + location)
  - Token storage resets when starting a new search (page 1)
- **Updated controllers**: Both `SearchController` and `MyTrialsController` now:
  - Initialize token storage for new searches
  - Retrieve appropriate page token from session based on page number
  - Store next page token in session when received from API
  - Track current page number for display
- **Updated views**: Standard pagination UI:
  - "Previous" button (when not on page 1)
  - "Page X" indicator in the middle
  - "Next" button (when more results available)
- **Preserved search params**: Added `pagination_params` helper method to maintain search criteria across pagination

**How it works:**
1. Page 1: No token needed, API returns `nextPageToken`
2. Token stored in session as `page_tokens[search_key][2]`
3. Page 2: Retrieve token from session, pass to API, store next token for page 3
4. User can go back to page 1 or forward to page 3
5. New search resets token storage for that search key

## Testing Checklist

### Basic Search Functionality
- [ ] Unauthenticated users can access public search
- [ ] Authenticated users without profiles are redirected to profile creation
- [ ] Authenticated users with profiles can access My Trials
- [ ] Search form pre-populates with profile data
- [ ] Auto-search works with default condition
- [ ] Manual search overrides profile defaults
- [ ] Trial cards link to correct detail pages in each context
- [ ] Navigation shows correct links based on authentication status
- [ ] Back links work correctly in both contexts
- [ ] Profile information displays correctly in authenticated views

### Pagination
- [ ] Pagination preserves search parameters (condition, location)
- [ ] Page 2+ of search results loads without errors
- [ ] Pagination URLs are clean (no action/controller params)
- [ ] Pagination works correctly when sorting by score

### Trial Scoring
- [ ] Match score badges display on trial cards in authenticated search
- [ ] Score badges show correct color based on match level (excellent/good/fair/poor)
- [ ] Sort by match score button appears in authenticated search
- [ ] Sorting by score reorders trials correctly
- [ ] Sorting by relevance returns to default order
- [ ] Sort selection persists across pagination
- [ ] Detail view shows overall match score in sidebar
- [ ] Detail view shows breakdown of all 6 scoring criteria
- [ ] Score breakdown displays correct percentages
- [ ] Score colors match the match level
- [ ] Scores are only shown for authenticated users (not in public search)
- [ ] Scores calculate correctly for users with complete profiles
- [ ] Scores handle missing profile data gracefully (neutral scores)


# Trial Scoring Implementation

## Overview

A comprehensive trial scoring system has been implemented to calculate compatibility scores between user profiles and clinical trials. This helps users quickly identify the most relevant trials for their specific situation.

## What Was Implemented

### 1. TrialScorer Service (`app/services/trial_scorer.rb`)

A dedicated service class that:
- Calculates a 0-100% match score based on 6 weighted criteria
- Returns a detailed breakdown showing each criterion's score
- Categorizes matches as excellent/good/fair/poor

#### Scoring Criteria & Weights

| Criterion | Weight | How It Works |
|-----------|--------|--------------|
| **Age** | 20% | Compares profile age with trial age requirements (min/max age) |
| **Sex** | 20% | Matches profile sex with trial sex requirements (male/female/all) |
| **Conditions** | 25% | Calculates overlap between profile conditions and trial conditions |
| **Location** | 15% | Scores based on proximity (city match=100%, state match=75%, other=25%) |
| **Study Type** | 10% | Matches preference (interventional/observational/either) |
| **Phase/Risk** | 10% | Aligns trial phase with user's risk tolerance |

#### Match Levels

- **Excellent** (80-100%): Strong match, highly compatible
- **Good** (60-79%): Good match, compatible with minor differences
- **Fair** (40-59%): Moderate match, some compatibility issues
- **Poor** (0-39%): Weak match, significant compatibility issues

### 2. Controller Updates (`app/controllers/my_trials_controller.rb`)

Enhanced both the index and show actions:

#### Index Action (Search Results)
- Calculates scores for all trials in search results
- Creates `@studies_with_scores` array with score data
- Supports sorting by score via `?sort_by=score` parameter
- Maintains pagination compatibility

#### Show Action (Detail View)
- Calculates score for individual trial
- Provides `@trial_score`, `@score_breakdown`, and `@match_level` to view

### 3. View Updates

#### Search Results (`app/views/my_trials/index.html.erb`)
- Added sort controls (Sort by Match / Sort by Relevance)
- Updated to iterate over `@studies_with_scores`
- Sort selection highlighted with color

#### Study Cards (`app/components/page/cards/study_card_component.html.erb`)
- Display colored match score badge at top of card
- Badge shows percentage and match level
- Includes checkmark icon for visual appeal

#### Detail View (`app/views/my_trials/show.html.erb`)
- Added match score card in sidebar
- Shows large overall score percentage
- Displays breakdown of all 6 criteria with individual scores
- Color-coded based on match level

### 4. Helper Methods (`app/helpers/application_helper.rb`)

Three new helper methods for consistent color coding:
- `match_score_bg_class(match_level)` - Background colors
- `match_score_border_class(match_level)` - Border colors
- `match_score_text_class(match_level)` - Text colors

Color scheme:
- Green: Excellent matches
- Blue: Good matches
- Yellow: Fair matches
- Gray: Poor matches

### 5. Component Updates (`app/components/page/cards/study_card_component.rb`)

Added `match_score_class` method to component for badge styling.

## How It Works

### For Users

1. **Search for Trials**: Navigate to "My Trial Search" (/my_trials)
2. **View Scores**: Each trial card shows a colored match score badge
3. **Sort Results**: Toggle between "Sort by Match" and "Sort by Relevance"
4. **See Details**: Click a trial to see detailed score breakdown in sidebar
5. **Understand Match**: Review individual criterion scores to see why a trial scored as it did

### Technical Flow

```
User Profile → TrialScorer → Calculate Weighted Score → Display Results
     ↓                              ↓
  Attributes              Age, Sex, Conditions,
  (age, sex,              Location, Study Type,
   conditions,            Phase/Risk
   location,
   preferences)
```

### Scoring Example

For a user with:
- Age: 45
- Sex: Female
- Conditions: [Type 2 Diabetes]
- Location: Boston, MA
- Risk Tolerance: Tested in other patients

Viewing a trial:
- Age Range: 18-65 → **100%** (within range)
- Sex: All → **100%** (accepts all)
- Conditions: [Diabetes Mellitus, Type 2 Diabetes] → **100%** (match)
- Locations: [Boston, MA; New York, NY] → **100%** (city match)
- Study Type: Interventional (user prefers interventional) → **100%**
- Phase: Phase 3 (user wants tested treatments) → **100%**

**Overall Score: 100% (Excellent Match)**

## Key Features

✅ **Intelligent Scoring**: Multi-factor algorithm considers all relevant criteria
✅ **Visual Feedback**: Color-coded badges for quick assessment
✅ **Transparency**: Detailed breakdown shows how scores are calculated
✅ **Flexible Sorting**: Sort by match score or API relevance
✅ **Graceful Degradation**: Handles missing profile data with neutral scores
✅ **Mobile Responsive**: Works on all screen sizes
✅ **Dark Mode Support**: All colors work in light and dark themes

## Files Modified

1. `app/services/trial_scorer.rb` (NEW)
2. `app/controllers/my_trials_controller.rb`
3. `app/views/my_trials/index.html.erb`
4. `app/views/my_trials/show.html.erb`
5. `app/components/page/cards/study_card_component.rb`
6. `app/components/page/cards/study_card_component.html.erb`
7. `app/helpers/application_helper.rb`
8. `AUTHENTICATED_SEARCH_SETUP.md`

## Testing Recommendations

### Manual Testing

1. **Create a test profile** with complete data (age, sex, conditions, location, preferences)
2. **Search for trials** and verify scores appear on cards
3. **Click "Sort by Match"** and verify trials reorder
4. **Click into a trial** and verify sidebar shows score breakdown
5. **Test with incomplete profile** (missing age, sex, etc.) and verify neutral scores
6. **Try pagination** and verify scores persist across pages
7. **Test dark mode** to ensure colors are readable

### Edge Cases to Test

- User with no conditions
- User with no location
- User with missing age
- User with missing sex
- User with "either" study type preference
- Trials with no age restrictions
- Trials with "All" sex requirement
- Trials with no location data
- Sorting + pagination combination

## Future Enhancements

Potential improvements:

1. **Geographic Distance**: Use Geocoding API to calculate actual miles to trial sites
2. **Score Filtering**: Filter trials by minimum score threshold (e.g., only show 60%+)
3. **Machine Learning**: Train on successful enrollments to improve scoring
4. **Custom Weights**: Let users adjust criterion weights based on priorities
5. **NLP Parsing**: Parse exclusion criteria text to enhance scoring accuracy
6. **Score History**: Track how scores change as trials/profiles update
7. **Notifications**: Alert users when high-scoring trials are added
8. **A/B Testing**: Test different weight distributions for optimal UX

## Notes

- Scores are **only calculated for authenticated users** with profiles
- Public search (`/search`) does **not** show scores
- Scores are calculated **on-the-fly** (not stored in database)
- Scoring algorithm can be easily **tuned** by adjusting weights in `TrialScorer::WEIGHTS`
- All styling uses **Tailwind CSS** classes for consistency

## Questions or Issues?

If you encounter any issues or have questions about the scoring algorithm, refer to:
- Service class: `app/services/trial_scorer.rb`
- Documentation: `AUTHENTICATED_SEARCH_SETUP.md` (Trial Score Feature section)


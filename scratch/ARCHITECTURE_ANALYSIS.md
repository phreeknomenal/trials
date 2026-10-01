# Clinical Trial Search App - Architecture Analysis & Roadmap

**Generated:** November 17, 2025  
**Project:** Rails 7 Clinical Trial Search Application  
**Purpose:** Strategic analysis, gap identification, and engineering roadmap

---

## 1. Project Scan & Current Architecture

### Models

#### Core User & Profile Models

**User** (`app/models/user.rb`)
- **Purpose:** Authentication and role management
- **Core Attributes:** 
  - `email`, `encrypted_password` (Devise)
  - `role` (member, employee, admin, super_admin)
  - Automatically creates associated `Profile` on creation
- **Associations:** `has_one :profile`
- **Notes:** Uses Devise for authentication; includes role-based helpers (`admin?`, `member?`, etc.)

**Profile** (`app/models/profile.rb`)
- **Purpose:** Comprehensive user profile with medical, demographic, and preference data
- **Core Attributes:**
  - Demographics: `first_name`, `last_name`, `birth_year`, `pronouns`, `sex_assigned_at_birth`, `ethnicity`
  - Location: `zip_code`, `city`, `state`, `country`
  - Medical: `diagnosis_timing`, `current_treatment`, `prior_treatment`
  - Trial Preferences: `willing_travel_miles`, `transportation_reliable`, `remote_visit_preference`, `trial_type_preference`, `risk_tolerance`
  - Contact: `phone_number`, `contact_preference`, `language_preference`
  - Status: `onboarded` (boolean)
- **Associations:**
  - `belongs_to :user`, `belongs_to :gender`, `belongs_to :race`
  - `has_many :conditions` (through `profile_conditions`)
  - `has_many :identities` (through `profile_identities`)
  - `has_many :interests` (through `profile_interests`)
  - `has_one_attached :avatar`
  - `has_rich_text :about`
- **Key Methods:**
  - `profile_completed?` - Checks if onboarding is complete
  - `age` - Calculates age from birth_year
  - `full_name` - Returns concatenated first/last name

#### Supporting Models

**Condition** (`app/models/condition.rb`)
- Medical conditions (e.g., "Breast Cancer", "Diabetes")
- Many-to-many with profiles via `profile_conditions`

**Identity** (`app/models/identity.rb`)
- User roles/identities (e.g., "Patient", "Caregiver", "Clinician")
- Many-to-many with profiles via `profile_identities`

**Interest** (`app/models/interest.rb`)
- User interests (e.g., "Support Groups", "Clinical Trials")
- Many-to-many with profiles via `profile_interests`

**Gender** & **Race** (`app/models/gender.rb`, `app/models/race.rb`)
- Simple lookup tables with `name` attribute
- Optional references from Profile

#### Join Models

**ProfileCondition** (`app/models/profile_condition.rb`)
- Includes `is_primary` flag to designate primary condition
- Business logic: only one primary condition allowed per profile
- Immutable after creation (profile_id and condition_id cannot be changed)

**ProfileIdentity** & **ProfileInterest**
- Standard join tables with immutability constraints

### Controllers

**HomeController** (`app/controllers/home_controller.rb`)
- **Route:** `GET /` (authenticated)
- **Current State:** Minimal - just renders the landing page
- **Purpose:** Shows marketing homepage for authenticated users

**SearchController** (`app/controllers/search_controller.rb`)
- **Routes:**
  - `GET /search` - Search form and results
  - `GET /search/:id` - Trial detail page
- **Key Methods:**
  - `index` - Displays search form; performs search if params present
  - `show` - Fetches single study by NCT ID
  - `perform_search` - Calls `ClinicalTrialClient.advanced_search` with pagination
- **Current Search Logic:**
  - Accepts `condition` and `location` parameters
  - No profile integration yet
  - Simple keyword matching via API
  - Basic pagination support

**ProfilesController** (`app/controllers/profiles_controller.rb`)
- **Routes:** `resources :profiles` (show, new, create, edit, update)
- **Features:**
  - Authorization via Pundit
  - Turbo Stream support for onboarding modal
  - Rich parameter handling (identities, interests, conditions, nested attributes)
- **Current State:** Well-implemented for profile CRUD

**ApplicationController** (`app/controllers/application_controller.rb`)
- Base controller with:
  - Pundit authorization
  - Pagy pagination
  - `ensure_profile_completed` hook (currently passive - just allows modal to show)
  - Layout switching based on authentication state

### Services/Helpers/Components

#### Services

**ClinicalTrialClient** (`app/services/clinical_trial_client.rb`)
- **Type:** Service object using HTTParty
- **API:** ClinicalTrials.gov API v2
- **Key Methods:**
  - `search(query, page:, page_size:)` - Simple text search
  - `advanced_search(condition:, location:, page:, page_size:)` - Multi-parameter search
  - `get_study(nct_id)` - Fetch single study details
- **Data Transformation:**
  - `format_study` - Transforms API response into flat hash structure
  - Extracts: title, status, summary, conditions, locations, eligibility, interventions, outcomes, contacts, etc.
  - Currently returns ~20 structured fields per study
- **Current Limitations:**
  - No caching
  - No retry logic
  - No rate limiting awareness
  - No profile-based filtering/ranking
  - Error handling is basic (returns error hash)

#### Helpers

**SearchHelper** (`app/helpers/search_helper.rb`)
- `status_badge_class(status)` - Returns Tailwind classes for status badges
- Simple presentation logic

**ApplicationHelper** (`app/helpers/application_helper.rb`)
- `parse_date` - Formats dates for display
- `parse_date_range` - Formats date ranges
- Includes Pagy helpers

**AuthenticationHelper** (`app/helpers/authentication_helper.rb`)
- `current_profile` - Convenience method to access `current_user.profile`

#### Components (ViewComponents)

**Page::Cards::StudyCardComponent** (`app/components/page/cards/study_card_component.rb`)
- **Purpose:** Reusable trial card for search results
- **Template:** `study_card_component.html.erb`
- **Displays:**
  - Title, NCT ID, Status badges
  - Phase, dates, sponsor, age range, conditions, locations
  - Brief summary (truncated to 3 lines)
  - "View Details" button
- **Current State:** Good foundation but no fit score display

**Page::Trials::TileComponent** (`app/components/page/trials/tile_component.rb`)
- **Purpose:** Key-value tile for trial details
- Simple component for displaying labeled data

**Profiles::OnboardingModalComponent** (`app/components/profiles/onboarding_modal_component.rb`)
- **Purpose:** Multi-step onboarding modal
- **Render Condition:** Only shows if profile not completed
- **Features:**
  - 3-step form (basic info, identities/interests, conditions)
  - Turbo-powered form submission
  - Stimulus-based navigation
- **Current State:** Well-implemented

---

## 2. Business Case Alignment & Gaps

### Pillar 1: Profiles as Foundation

**✅ What's Present:**
- Comprehensive Profile model with rich attributes
- Demographics (age, gender, race, ethnicity, sex)
- Location data (zip_code, city, state)
- Medical conditions via many-to-many relationship
- Identities (patient, caregiver, etc.) via many-to-many
- Trial preferences (travel distance, remote visits, risk tolerance, trial types)
- Treatment history fields (diagnosis_timing, current_treatment, prior_treatment)
- Onboarding flow with modal to complete profile

**⚠️ What's Partial:**
- Profile data is collected but **not actively used in search**
- `SearchController#perform_search` only uses URL params (condition, location), ignores `current_user.profile`
- No "Search based on my profile" feature

**❌ What's Missing:**
- Profile-to-trial matching logic
- No service to extract search criteria from profile
- No "Use My Profile" button/feature in search interface
- Treatment history not used for filtering (e.g., "exclude trials requiring prior chemo")
- Preference-based filtering (e.g., "only show remote-friendly trials")

**References:**
- `SearchController#perform_search` (lines 18-30) - bypasses profile entirely
- `Profile` model has extensive data but no integration point with search

---

### Pillar 2: Personalized Search & Fit Score

**✅ What's Present:**
- API client retrieves comprehensive trial data
- Eligibility criteria text is fetched (inclusion_criteria field)
- Age ranges, sex requirements available in API response
- Location data available in both profile and trial results

**⚠️ What's Partial:**
- Search results displayed but in raw order from API (no ranking)
- Trial cards show data but no "why this matches you" explanation

**❌ What's Missing:**
- **No Fit Score Service:** No `Trials::FitScoreService` or equivalent
- **No Eligibility Matcher:** No logic to parse/match eligibility criteria against profile
- **No Ranking Algorithm:** Trials shown in API order, not personalized relevance
- **No Match Explanation:** Cards don't show "92% match because..." text
- **No Profile-Based Scoring Dimensions:**
  - Distance calculation (profile zip vs trial locations)
  - Condition match quality (primary vs secondary conditions)
  - Age/sex eligibility check
  - Preference alignment (remote visits, trial type, risk tolerance)
  - Recruitment status weighting
- **No Saved Calculations:** Every page load would recalculate (if it existed)

**Suggested Target Components (Missing):**
```
app/services/
  trials/
    search_service.rb         # Orchestrates search + scoring
    fit_score_service.rb      # Calculates fit score for profile + study
    eligibility_matcher.rb    # Parses criteria, checks profile eligibility
    location_scorer.rb        # Geocoding + distance calculation
```

**References:**
- `SearchController#perform_search` returns raw `@studies` array
- `StudyCardComponent` renders trial data but no score
- `ClinicalTrialClient.format_study` returns data hash but no profile-aware logic

---

### Pillar 3: Trust + Transparency in the UI

**✅ What's Present:**
- Clean, modern Tailwind-based UI with gradient design
- Status badges with color coding (recruiting, completed, etc.)
- Detailed trial page (`search/show.html.erb`) with:
  - Comprehensive study overview
  - Eligibility criteria displayed
  - Locations with map pin icons
  - Contact information
  - Outcome measures
  - Interventions/treatments
- Reusable StudyCardComponent for consistency
- "View on ClinicalTrials.gov" external link
- "Save to My Trials" button (UI only, not functional yet)

**⚠️ What's Partial:**
- Study cards are informative but don't explain **why** the trial was shown
- No visual fit score indicator (badge, percentage, stars)
- No "Good fit because you..." section

**❌ What's Missing:**
- **Fit Score Badge/Indicator:** No visual score on cards or detail pages
- **Match Explanation Component:** No "Why This Trial Matches You" section explaining:
  - Condition alignment
  - Location proximity
  - Eligibility likelihood
  - Preference match
- **Trust Indicators:**
  - No sponsor reputation/explanation (e.g., "Academic Medical Center" vs "Pharmaceutical Company")
  - No clarity score for eligibility criteria (simple vs complex language)
  - No diversity indicators (trial demographics vs user demographics)
- **Comparison Tools:** No side-by-side trial comparison
- **Educational Content:** No tooltips or help text explaining phases, masking, allocation, etc.

**Suggested Missing Components:**
```
app/components/
  trials/
    fit_score_badge_component.rb       # Visual score display
    match_explanation_component.rb     # "Why this trial" breakdown
    eligibility_check_component.rb     # Green/yellow/red check for requirements
```

**Home Page State:**
- `home/index.html.erb` is a marketing page with:
  - Hero section with CTA buttons
  - Static category cards (hardcoded "Oncology", "Neurology", etc.)
  - "How it works" section (mentions fit score but doesn't exist yet)
  - Testimonial section
- **Gap:** Home doesn't show personalized recommendations or recent searches
- **Gap:** No dynamic trial count or featured trials
- **Gap:** "Get Started" button should go to profile setup or personalized search

---

### Pillar 4: Roadmap Readiness

**✅ Current Structural Strengths:**
- Clean MVC separation with ViewComponents
- Turbo/Stimulus setup for modern interactivity
- Pundit for authorization (ready for multi-role features)
- Rich profile model ready for expansion
- Service object pattern started with ClinicalTrialClient

**⚠️ Partial Readiness:**
- Routes have `resources :my_trials` defined but no controller (placeholder for saved trials)
- Profile has `interests` field but not used yet (ready for educational content tagging)

**❌ Not Ready For (Future Features):**

**Saved Trials / Watchlist:**
- No `SavedTrial` or `TrialWatchlist` model
- No controller for `my_trials` route
- No database table to persist saved trials
- No bookmark/save action in UI

**Educational Content:**
- No `Article`, `Resource`, or `ContentPage` models
- No CMS or admin interface for content
- No content recommendation engine

**Community/Engagement:**
- No `Comment`, `Discussion`, or `Forum` models
- No user-to-user messaging
- No notification system

**Analytics/Tracking:**
- No `SearchEvent` or `ViewEvent` models
- No analytics service integration
- No user journey tracking

**Structural Choices That May Cause Pain:**
- **Trial Data Not Cached:** Every search hits external API (slow, rate limit risk)
- **No PORO for Trial:** Studies are plain hashes, not objects with methods (hard to add behavior)
- **Eligibility Criteria as Text Blob:** No structured parsing (makes matching hard)
- **No Background Jobs:** API calls are synchronous (blocks requests)

---

## 3. Technical Debt & Architecture Issues

### Issue 1: Business Logic in Controller

**Location:** `SearchController#perform_search` (lines 18-30)

**Problem:**
- Search orchestration lives in controller
- Violates Single Responsibility Principle
- Hard to test independently
- Can't reuse search logic elsewhere (e.g., background jobs, API endpoints)

**Impact:**
- Adding fit score would bloat controller further
- Can't easily add pre/post-search hooks
- Difficult to swap API providers

**Refactor Direction:**
Create dedicated service:
```ruby
# app/services/trials/search_service.rb
class Trials::SearchService
  def initialize(profile: nil, params: {})
    @profile = profile
    @params = params
  end

  def call
    # Extract criteria from params or profile
    # Call API client
    # Transform results
    # Apply fit scoring if profile present
    # Return structured result object
  end
end
```

Then controller becomes:
```ruby
def perform_search
  result = Trials::SearchService.new(
    profile: current_user&.profile,
    params: sanitized_params
  ).call
  
  @studies = result.studies
  @total_count = result.total_count
  # ...
end
```

---

### Issue 2: Trial Data as Unstructured Hash

**Location:** `ClinicalTrialClient.format_study` returns plain hash

**Problem:**
- Trial data is represented as `Hash` throughout application
- No encapsulation or behavior
- Can't add methods like `study.eligible_for?(profile)` or `study.distance_from(zip_code)`
- Difficult to add computed fields

**Impact:**
- All trial logic scattered in views and helpers
- Can't unit test trial-specific behavior
- Hard to add caching or memoization

**Refactor Direction:**
Create PORO (Plain Old Ruby Object):
```ruby
# app/models/trials/study.rb
class Trials::Study
  attr_reader :nct_id, :title, :status, :conditions, # ...

  def initialize(attributes = {})
    attributes.each { |k, v| instance_variable_set("@#{k}", v) }
  end

  def self.from_api(hash)
    new(hash)
  end

  def recruiting?
    status == "Recruiting"
  end

  def matches_condition?(condition_name)
    conditions.any? { |c| c.downcase.include?(condition_name.downcase) }
  end

  def primary_location
    locations&.first
  end
  
  # Future: fit score integration
  def fit_score_for(profile)
    @fit_score ||= Trials::FitScoreService.new(self, profile).calculate
  end
end
```

---

### Issue 3: No API Response Caching

**Location:** `ClinicalTrialClient` - every call hits external API

**Problem:**
- No caching layer for API responses
- Same trial fetched multiple times (search → detail → back → detail)
- Risk of hitting rate limits
- Slow page loads

**Impact:**
- Poor user experience (slow searches)
- Unnecessary API load
- Can't work offline/demo easily
- Hard to add features that require multiple trial lookups (comparison, etc.)

**Refactor Direction:**
Add caching layer:
```ruby
# Option 1: Rails cache with TTL
def self.get_study(nct_id)
  Rails.cache.fetch("trial:#{nct_id}", expires_in: 24.hours) do
    # ... existing API call
  end
end

# Option 2: Database-backed cache (future)
# Create Trial model to persist frequently accessed trials
```

---

### Issue 4: Inline Eligibility Criteria (No Parsing)

**Location:** Eligibility criteria stored as text blob

**Problem:**
- Eligibility criteria is unstructured text (often bullet points and paragraphs)
- No parsing into inclusion vs exclusion criteria
- Can't programmatically check if profile meets criteria
- Makes fit score implementation very hard

**Example raw criteria:**
```
Inclusion Criteria:
- Age 18-65 years
- Diagnosed with Type 2 Diabetes
- HbA1c > 7.0%

Exclusion Criteria:
- Pregnant or breastfeeding
- Prior heart attack
```

**Impact:**
- Fit score must be "best guess" without actual eligibility check
- Can't provide "You meet 4 of 5 inclusion criteria" feedback
- Risk of showing ineligible trials prominently

**Refactor Direction (Long-term):**
```ruby
# app/services/trials/eligibility_parser.rb
class Trials::EligibilityParser
  def parse(criteria_text)
    {
      inclusion: extract_inclusion_criteria(criteria_text),
      exclusion: extract_exclusion_criteria(criteria_text),
      age_range: extract_age_range(criteria_text),
      sex_requirement: extract_sex(criteria_text)
      # ... more structured fields
    }
  end
end

# app/services/trials/eligibility_matcher.rb
class Trials::EligibilityMatcher
  def initialize(study, profile)
    @study = study
    @profile = profile
  end

  def eligible?
    age_eligible? && sex_eligible? && !excluded?
  end

  def match_score
    # Calculate % of criteria matched
  end
end
```

**Short-term workaround:**
- Extract simple rules (age, sex) from structured fields
- Use keyword matching for conditions
- Display eligibility as "potential match" vs "confirmed eligible"

---

### Issue 5: No Separation Between Search Types

**Location:** Single search method handles all use cases

**Problem:**
- `SearchController` handles both:
  - Manual search (user enters condition/location)
  - Future: Profile-based search
  - Future: Saved search re-run
  - Future: Similar trials lookup
- No separation of concerns

**Impact:**
- Controller will become unwieldy
- Hard to A/B test different search algorithms
- Can't easily add ML-based search later

**Refactor Direction:**
Create specialized search strategies:
```ruby
# app/services/trials/search/
#   manual_search.rb      - User-entered params
#   profile_search.rb     - Profile-driven search
#   similar_search.rb     - Find similar to given trial
#   saved_search.rb       - Re-run saved search
```

---

### Issue 6: Missing Model for Trial Interactions

**Location:** No `SavedTrial` or interaction models

**Problem:**
- UI shows "Save to My Trials" button but no backend
- Route `resources :my_trials` exists but no controller
- Can't track user engagement (views, saves, contacts)

**Impact:**
- Can't build engagement features
- Can't improve recommendations based on user behavior
- No data for analytics

**Files to Create:**
```ruby
# Migration
class CreateSavedTrials < ActiveRecord::Migration[8.0]
  def change
    create_table :saved_trials do |t|
      t.references :profile, null: false, foreign_key: true
      t.string :nct_id, null: false
      t.string :status, default: 'saved' # saved, contacted, enrolled, declined
      t.text :notes
      t.datetime :contacted_at
      t.timestamps
    end
    add_index :saved_trials, [:profile_id, :nct_id], unique: true
  end
end

# Model
class SavedTrial < ApplicationRecord
  belongs_to :profile
  validates :nct_id, presence: true, uniqueness: { scope: :profile_id }
end

# Controller
class MyTrialsController < ApplicationController
  def index
    @saved_trials = current_user.profile.saved_trials.order(created_at: :desc)
  end
  
  def create
    current_user.profile.saved_trials.create!(saved_trial_params)
  end
  
  def destroy
    current_user.profile.saved_trials.find(params[:id]).destroy
  end
end
```

---

### Issue 7: Location Data Not Geocoded

**Location:** Profile has `zip_code` but no lat/lng

**Problem:**
- Can't calculate distance to trial sites
- Location matching is text-based only
- Can't implement "within X miles" filtering accurately

**Impact:**
- Fit score can't include distance component
- Can't sort by proximity
- User has to manually check if trial is nearby

**Refactor Direction:**
```ruby
# Add to Profile migration
add_column :profiles, :latitude, :decimal, precision: 10, scale: 6
add_column :profiles, :longitude, :decimal, precision: 10, scale: 6

# Geocode on save
class Profile < ApplicationRecord
  after_validation :geocode_zip_code, if: :zip_code_changed?
  
  def geocode_zip_code
    # Use geocoding service (Geocoder gem, Google Maps API, etc.)
    result = Geocoder.search(zip_code).first
    if result
      self.latitude = result.latitude
      self.longitude = result.longitude
    end
  end
end

# Distance calculation service
class Trials::LocationScorer
  def distance_miles(profile_coords, trial_coords)
    Geocoder::Calculations.distance_between(profile_coords, trial_coords)
  end
end
```

---

## 4. Recommended Architectural Shape (Target)

### Core Models and Relationships

```
User
  ├── has_one Profile (1:1)
  └── authentication, roles

Profile (rich patient data)
  ├── belongs_to User (1:1)
  ├── has_many Conditions (M:N via profile_conditions)
  ├── has_many Identities (M:N via profile_identities)
  ├── has_many Interests (M:N via profile_interests)
  ├── has_many SavedTrials (1:N) ⭐ NEW
  ├── has_many SearchHistories (1:N) ⭐ NEW
  └── demographics, location, preferences

SavedTrial ⭐ NEW
  ├── belongs_to Profile
  ├── nct_id (string, indexed)
  ├── status (saved, contacted, enrolled, declined)
  ├── notes, contacted_at
  └── cached_study_data (jsonb, optional for offline access)

SearchHistory ⭐ NEW (optional, for analytics)
  ├── belongs_to Profile
  ├── search_params (jsonb)
  ├── results_count
  └── timestamps

# Trial data remains external (API-driven)
# But wrapped in PORO for behavior
```

---

### Services / POROs

Organize services under `app/services/trials/` namespace:

```
app/services/trials/
  ├── search_service.rb           ⭐ Orchestrates search flow
  ├── fit_score_service.rb        ⭐ Calculates fit score for profile + study
  ├── eligibility_matcher.rb      ⭐ Checks eligibility match
  ├── location_scorer.rb          ⭐ Calculates distance score
  ├── preference_scorer.rb        ⭐ Scores based on trial preferences
  ├── eligibility_parser.rb       ⭐ Parses criteria text (long-term)
  └── search/
      ├── manual_search.rb        Strategy for manual search
      ├── profile_search.rb       ⭐ Strategy for profile-driven search
      └── similar_search.rb       (Future)

app/models/trials/
  └── study.rb                    ⭐ PORO wrapping trial data hash

app/services/
  └── clinical_trial_client.rb   ✅ Existing API client (add caching)
```

**Service Responsibilities:**

**Trials::SearchService** (orchestrator)
- Accept search params + optional profile
- Call API client
- Transform results to Study objects
- If profile present, apply fit scoring
- Return structured SearchResult object

**Trials::FitScoreService**
- Input: Study object + Profile object
- Output: Float score (0.0-100.0) + breakdown hash
- Scoring dimensions:
  - Condition match (40%): Primary condition exact match, secondary conditions
  - Location (25%): Distance in miles from profile zip
  - Eligibility (20%): Age, sex, basic criteria match
  - Preferences (10%): Remote visit, trial type, risk tolerance alignment
  - Recruitment status (5%): Bonus for "Recruiting"
- Return: `{ score: 87.5, breakdown: { condition: 40, location: 22, ... } }`

**Trials::EligibilityMatcher**
- Extract age range, sex from study
- Compare against profile
- Keyword scan for conditions in criteria text
- Return: `{ eligible: true/false/unknown, confidence: 0-100, reasons: [] }`

**Trials::LocationScorer**
- Geocode profile zip if needed
- Parse trial locations (city, state)
- Calculate distance to nearest site
- Return: `{ distance_miles: 12.3, nearest_location: "Boston, MA" }`

---

### View Components / Partials

Expand component library:

```
app/components/
  ├── trials/
  │   ├── fit_score_badge_component.rb       ⭐ NEW - Visual score display
  │   ├── match_explanation_component.rb     ⭐ NEW - "Why this trial" breakdown
  │   ├── eligibility_check_component.rb     ⭐ NEW - Requirement checklist
  │   ├── study_card_component.rb           ✅ Existing (enhance with fit score)
  │   └── study_comparison_component.rb      (Future)
  │
  ├── page/
  │   ├── cards/
  │   │   ├── study_card_component.rb        ✅ Existing
  │   │   └── saved_trial_card_component.rb  ⭐ NEW
  │   └── trials/
  │       └── tile_component.rb              ✅ Existing
  │
  ├── profiles/
  │   ├── onboarding_modal_component.rb      ✅ Existing
  │   └── onboarding_form_component.rb       ✅ Existing
  │
  └── search/
      ├── profile_search_button_component.rb ⭐ NEW - "Use My Profile" button
      └── search_filters_component.rb        (Future enhancement)
```

**Component Details:**

**Trials::FitScoreBadgeComponent**
- Props: `score` (Float), `size` (:sm, :md, :lg)
- Renders: Circular badge with color gradient (red→yellow→green based on score)
- Shows: "87% Match"

**Trials::MatchExplanationComponent**
- Props: `study` (Study object), `profile` (Profile), `breakdown` (Hash from FitScoreService)
- Renders: Expandable section with:
  - "Why this trial is a good fit"
  - Breakdown by category (condition, location, eligibility, preferences)
  - Visual indicators (checkmarks, distances)
  - "Things to discuss with your doctor" callout

**Trials::EligibilityCheckComponent**
- Props: `study`, `profile`, `eligibility_match` (from EligibilityMatcher)
- Renders: Checklist of requirements:
  - ✅ Age: 45 (within 18-65 range)
  - ✅ Sex: Female (matches requirement)
  - ✅ Condition: Breast Cancer (exact match)
  - ⚠️  Location: 25 miles away (review travel)
  - ❓ Other criteria: Manual review needed

---

### Controllers

Clean separation of concerns:

**SearchController**
- `index` - Display search form, delegate search to service
- `show` - Display single trial details with fit score

**MyTrialsController** ⭐ NEW
- `index` - List saved trials
- `create` - Save a trial
- `update` - Update status/notes
- `destroy` - Remove saved trial

**ProfilesController** ✅ Existing
- Continue handling profile CRUD
- Ensure profile completion drives search quality

**TrialsController** (Optional future refactor)
- Split off trial-specific logic from SearchController
- `index` - Browse/search trials
- `show` - Trial details
- `compare` - Side-by-side comparison

---

### Routes

```ruby
Rails.application.routes.draw do
  # Existing
  resources :profiles, only: [:show, :edit, :update]
  
  # Search
  resources :search, only: [:index, :show] do
    collection do
      get :profile_search  ⭐ NEW - Search using profile
    end
  end
  
  # Saved Trials
  resources :my_trials, only: [:index, :create, :update, :destroy] do
    member do
      patch :update_status  ⭐ NEW - Quick status updates
    end
  end
  
  # Future: Recommendations, Comparisons, etc.
end
```

---

## 5. Concrete Gap List (MVP vs Current)

| MVP Feature | Current State | What's Missing |
|-------------|---------------|----------------|
| **Profile-based search** | ❌ Missing | • No integration between Profile and SearchController<br>• No "Use My Profile" button in UI<br>• SearchService doesn't accept profile parameter |
| **Fit score** | ❌ Missing | • No Trials::FitScoreService<br>• No scoring algorithm (condition, location, eligibility, preferences)<br>• No score display in StudyCardComponent<br>• No breakdown/explanation of score |
| **Trial cards with personalization** | ⚠️  Partial | • StudyCardComponent exists but generic<br>• No fit score badge<br>• No "Why this matches you" section<br>• No eligibility indicators |
| **Basic profile onboarding flow** | ✅ Implemented | • Onboarding modal works<br>• 3-step form collects conditions, identities, interests<br>• Profile completion check in place<br>**Enhancement opportunity:** Add trial preference questions |
| **Clean home page with story** | ⚠️  Partial | • Marketing homepage exists with value prop<br>• Static content only (no personalization)<br>• "How it works" mentions fit score but doesn't exist<br>• No dynamic trial recommendations<br>• No quick search from homepage |
| **Eligibility matching** | ❌ Missing | • No EligibilityMatcher service<br>• Criteria stored as text blob (not parsed)<br>• No "You meet X of Y criteria" feedback<br>• Age/sex checks not automated |
| **Location-based filtering** | ⚠️  Partial | • Profile has zip_code<br>• Trials return locations<br>**Missing:** Geocoding, distance calculation, "within X miles" filter |
| **Trial detail transparency** | ✅ Well-implemented | • Comprehensive detail page<br>• Clear display of eligibility, interventions, outcomes, contacts<br>**Enhancement:** Add personalized eligibility check |
| **Saved trials / bookmarking** | ❌ Missing | • UI button exists but non-functional<br>• No SavedTrial model<br>• No MyTrialsController implementation<br>• Route defined but not connected |
| **Preference-based ranking** | ❌ Missing | • Profile collects preferences (travel, remote visits, risk, trial type)<br>• Preferences not used in search or ranking<br>• No preference matching logic |

---

## 6. Prioritized Roadmap (Engineering Plan)

### Phase 1 – MVP Hardening (Now)

**Goal:** Get profile-based search working with basic fit score

---

#### 1.1 Create Study PORO
**Effort:** 2-4 hours  
**Files to create/modify:**
- `app/models/trials/study.rb` (NEW)
- `app/services/clinical_trial_client.rb` (MODIFY)

**Tasks:**
1. Create `Trials::Study` class to wrap trial hash
2. Add convenience methods: `recruiting?`, `primary_location`, `age_range`, etc.
3. Update `ClinicalTrialClient` to return Study objects instead of hashes
4. Update views to work with Study objects (minimal changes due to method_missing compatibility)

**Why now:** Foundation for all other scoring/matching work

---

#### 1.2 Implement Trials::FitScoreService
**Effort:** 8-12 hours  
**Files to create:**
- `app/services/trials/fit_score_service.rb` (NEW)
- `app/services/trials/eligibility_matcher.rb` (NEW)
- `app/services/trials/location_scorer.rb` (NEW)
- `app/services/trials/preference_scorer.rb` (NEW)

**Tasks:**
1. **FitScoreService** - Main orchestrator:
   ```ruby
   def initialize(study, profile)
     @study = study
     @profile = profile
   end

   def calculate
     return nil unless @profile
     
     scores = {
       condition: condition_score,    # 0-40 points
       location: location_score,      # 0-25 points
       eligibility: eligibility_score, # 0-20 points
       preferences: preference_score,  # 0-10 points
       status: status_score            # 0-5 points
     }
     
     {
       total: scores.values.sum,
       breakdown: scores,
       explanations: generate_explanations(scores)
     }
   end
   ```

2. **EligibilityMatcher** - Basic checks:
   - Age range match (extract from study.min_age/max_age)
   - Sex match (study.sex vs profile.sex_assigned_at_birth)
   - Condition keyword match in study.conditions
   - Return confidence level

3. **LocationScorer** - Stub for now (full geocoding in 1.4):
   - Text match between profile.state and study locations
   - Return placeholder distance or low score if no state match

4. **PreferenceScorer**:
   - Check trial_type_preference (interventional/observational/either)
   - Check remote_visit_preference (look for "remote" keywords in study)
   - Risk tolerance (map phase to risk level)

**Why now:** Core differentiator of the product

---

#### 1.3 Integrate Fit Score into Search Flow
**Effort:** 6-8 hours  
**Files to create/modify:**
- `app/services/trials/search_service.rb` (NEW)
- `app/controllers/search_controller.rb` (MODIFY)
- `app/components/page/cards/study_card_component.rb` (MODIFY)
- `app/components/page/cards/study_card_component.html.erb` (MODIFY)

**Tasks:**
1. Create SearchService:
   ```ruby
   class Trials::SearchService
     def initialize(params: {}, profile: nil)
       @params = params
       @profile = profile
     end

     def call
       # Get results from API client
       studies = ClinicalTrialClient.advanced_search(**@params)
       
       # Wrap in Study objects
       studies = studies[:studies].map { |h| Trials::Study.from_api(h) }
       
       # Calculate fit scores if profile present
       if @profile
         studies = studies.map do |study|
           score_data = Trials::FitScoreService.new(study, @profile).calculate
           study.instance_variable_set(:@fit_score_data, score_data)
           study
         end
         
         # Sort by fit score
         studies.sort_by! { |s| -s.fit_score_data[:total] }
       end
       
       SearchResult.new(studies: studies, ...)
     end
   end
   ```

2. Update SearchController to use SearchService:
   ```ruby
   def perform_search
     result = Trials::SearchService.new(
       params: sanitized_params,
       profile: current_user&.profile
     ).call
     
     @studies = result.studies
     # ...
   end
   ```

3. Enhance StudyCardComponent to display fit score:
   - Add `score` attribute to component
   - Display badge if score present
   - Add "Based on your profile" tag

**Why now:** Makes fit score visible to users immediately

---

#### 1.4 Add Geocoding & Distance Calculation
**Effort:** 4-6 hours  
**Files to modify:**
- `db/migrate/XXXXXX_add_geocoding_to_profiles.rb` (NEW)
- `app/models/profile.rb` (MODIFY)
- `app/services/trials/location_scorer.rb` (MODIFY)
- `Gemfile` (ADD geocoder gem)

**Tasks:**
1. Add geocoder gem: `gem 'geocoder'`
2. Migration:
   ```ruby
   add_column :profiles, :latitude, :decimal, precision: 10, scale: 6
   add_column :profiles, :longitude, :decimal, precision: 10, scale: 6
   ```

3. Update Profile model:
   ```ruby
   geocoded_by :zip_code
   after_validation :geocode, if: :zip_code_changed?
   ```

4. Update LocationScorer to calculate real distances:
   - Geocode trial city/state on the fly (with caching)
   - Use Geocoder::Calculations.distance_between
   - Return actual miles
   - Score: 25 points for <10mi, linear decay to 0 at 100mi

5. Backfill existing profiles: `Profile.where.not(zip_code: nil).find_each(&:geocode)`

**Why now:** Distance is a key component of fit score accuracy

---

#### 1.5 Create Fit Score Display Components
**Effort:** 6-8 hours  
**Files to create:**
- `app/components/trials/fit_score_badge_component.rb` (NEW)
- `app/components/trials/fit_score_badge_component.html.erb` (NEW)
- `app/components/trials/match_explanation_component.rb` (NEW)
- `app/components/trials/match_explanation_component.html.erb` (NEW)

**Tasks:**
1. **FitScoreBadgeComponent**:
   - Circular badge with percentage
   - Color gradient: <50 red, 50-75 yellow, 75+ green
   - Props: score (Float), size (:sm, :md, :lg)

2. **MatchExplanationComponent**:
   - Collapsible/expandable section
   - Display breakdown: Condition (40/40), Location (18/25), etc.
   - Visual icons for each category
   - Explanations: "Primary condition match", "12 miles from Boston, MA"
   - Props: study, profile, fit_score_data

3. Add to StudyCardComponent (list view)
4. Add to search/show.html.erb (detail view)

**Why now:** Transparency builds trust; users understand why trials are shown

---

#### 1.6 Add "Use My Profile" Search Feature
**Effort:** 4-6 hours  
**Files to create/modify:**
- `app/controllers/search_controller.rb` (ADD profile_search action)
- `app/views/search/index.html.erb` (ADD button)
- `app/services/trials/profile_search_builder.rb` (NEW)

**Tasks:**
1. Create ProfileSearchBuilder service:
   ```ruby
   class Trials::ProfileSearchBuilder
     def initialize(profile)
       @profile = profile
     end

     def build_search_params
       {
         condition: @profile.conditions.where(is_primary: true).first&.name,
         location: "#{@profile.city}, #{@profile.state}" || @profile.zip_code
       }
     end
   end
   ```

2. Add profile_search action:
   ```ruby
   def profile_search
     unless current_user&.profile&.profile_completed?
       redirect_to search_index_path, alert: "Complete your profile first"
       return
     end
     
     params = Trials::ProfileSearchBuilder.new(current_user.profile).build_search_params
     redirect_to search_index_path(params)
   end
   ```

3. Add button to search/index.html.erb:
   ```erb
   <% if current_user&.profile&.profile_completed? %>
     <%= link_to "Search Based on My Profile", 
                 profile_search_search_index_path,
                 class: "btn-primary" %>
   <% end %>
   ```

4. Update homepage to link to profile search instead of generic search

**Why now:** Makes profile data immediately valuable

---

#### 1.7 Enhance Home Page with Personalization
**Effort:** 4-6 hours  
**Files to modify:**
- `app/views/home/index.html.erb` (MODIFY)
- `app/controllers/home_controller.rb` (MODIFY)

**Tasks:**
1. Update HomeController to fetch featured trials if user authenticated:
   ```ruby
   def index
     if user_signed_in? && current_user.profile.profile_completed?
       result = Trials::SearchService.new(
         params: Trials::ProfileSearchBuilder.new(current_user.profile).build_search_params,
         profile: current_user.profile
       ).call
       
       @recommended_trials = result.studies.first(3)
     end
   end
   ```

2. Update home page:
   - Show personalized trial recommendations if logged in
   - Display "Trials matching your profile" section
   - Add fit score badges
   - Keep marketing content for unauthenticated users

3. Add dynamic statistics:
   - Count of conditions in database
   - Number of trials currently recruiting (cached)

**Why now:** Home page should reflect app's value immediately

---

### Phase 2 – Growth (Next 4-8 weeks)

**Goal:** Add engagement features and onboarding improvements

---

#### 2.1 Saved Trials / Bookmarking
**Effort:** 8-12 hours  
**Files to create:**
- `db/migrate/XXXXXX_create_saved_trials.rb` (NEW)
- `app/models/saved_trial.rb` (NEW)
- `app/controllers/my_trials_controller.rb` (NEW)
- `app/views/my_trials/index.html.erb` (NEW)
- `app/components/page/cards/saved_trial_card_component.rb` (NEW)
- `app/policies/saved_trial_policy.rb` (NEW)

**Tasks:**
1. Migration:
   ```ruby
   create_table :saved_trials do |t|
     t.references :profile, null: false, foreign_key: true
     t.string :nct_id, null: false
     t.string :status, default: 'saved' # saved, contacted, enrolled, declined, ineligible
     t.text :notes
     t.datetime :contacted_at
     t.jsonb :cached_study_data # Cache key trial info for offline/fast access
     t.timestamps
   end
   add_index :saved_trials, [:profile_id, :nct_id], unique: true
   ```

2. Model with validations and status enum

3. Controller with CRUD actions

4. Views:
   - List view with status filters
   - Notes field for each trial
   - Quick status updates (dropdown)
   - Link back to trial details

5. Add bookmark button to StudyCardComponent and search/show page

6. Policy to ensure users only see their own saved trials

---

#### 2.2 Enhanced Onboarding with Trial Preferences
**Effort:** 6-8 hours  
**Files to modify:**
- `app/components/profiles/onboarding_form_component.html.erb` (ADD step)

**Tasks:**
1. Add Step 4 to onboarding modal: "Trial Preferences"
   - Willing to travel: 10, 25, 50, 100+ miles (radio buttons)
   - Transportation: Do you have reliable transportation? (yes/no)
   - Remote visits: Preference (in-person / hybrid / remote)
   - Trial type: Interventional, observational, or either
   - Risk tolerance: Approved treatments only / Tested in others / Early-stage OK

2. Update ProfilesController to accept new params

3. Show preview of how preferences affect search results

**Why:** Better preferences = better fit scores

---

#### 2.3 Educational Content Section
**Effort:** 12-16 hours  
**Files to create:**
- `db/migrate/XXXXXX_create_articles.rb` (NEW)
- `app/models/article.rb` (NEW)
- `app/controllers/articles_controller.rb` (NEW)
- `app/views/articles/` (NEW directory)
- `app/admin/articles.rb` (if using ActiveAdmin/similar)

**Tasks:**
1. Create Article model:
   - title, slug, body (ActionText), published_at, category
   - Tags (via acts-as-taggable or simple array field)
   - Featured image

2. Build simple CMS or integrate ActiveAdmin

3. Article categories:
   - Understanding Clinical Trials
   - Trial Phases Explained
   - Patient Rights
   - How to Talk to Your Doctor
   - Diversity in Clinical Trials

4. Link articles from:
   - Homepage ("Learn More" section)
   - Trial detail pages (related articles based on conditions/phase)
   - Search results (sidebar "Related Resources")

5. Tag articles with conditions/interests for personalization

---

#### 2.4 Search History & Recent Searches
**Effort:** 4-6 hours  
**Files to create:**
- `db/migrate/XXXXXX_create_search_histories.rb` (NEW)
- `app/models/search_history.rb` (NEW)
- `app/controllers/search_controller.rb` (MODIFY)

**Tasks:**
1. Migration:
   ```ruby
   create_table :search_histories do |t|
     t.references :profile, null: false, foreign_key: true
     t.jsonb :search_params
     t.integer :results_count
     t.timestamps
   end
   ```

2. Log searches in SearchController after each search:
   ```ruby
   current_user.profile.search_histories.create!(
     search_params: sanitized_params,
     results_count: @total_count
   )
   ```

3. Display recent searches:
   - On search page (sidebar or top)
   - "Search again" links
   - Analytics dashboard (future)

---

#### 2.5 Email Notifications for New Matching Trials
**Effort:** 10-14 hours  
**Files to create:**
- `db/migrate/XXXXXX_create_saved_searches.rb` (NEW)
- `app/models/saved_search.rb` (NEW)
- `app/jobs/trial_notification_job.rb` (NEW)
- `app/mailers/trial_mailer.rb` (NEW or extend existing)
- `config/recurring.yml` (MODIFY for daily job)

**Tasks:**
1. Create SavedSearch model:
   - profile_id, search_params (jsonb), last_checked_at, notification_frequency

2. Allow users to "Save this search" and opt-in to notifications

3. Background job (daily):
   - Loop through saved searches
   - Run search and compare to cached results
   - If new high-fit trials found, send email

4. Email template:
   - "3 new trials match your profile"
   - Show trial cards with fit scores
   - CTA: "View All Matches"

5. User preferences page to manage saved searches

---

### Phase 3 – Advanced (Future / 3+ months out)

**Goal:** AI assistance, integrations, researcher features

---

#### 3.1 AI/LLM Helper for Trial Explanations
**Effort:** 16-24 hours  
**Epics:**
- **Epic: Natural Language Trial Summaries**
  - Integrate OpenAI API or similar
  - Generate plain-language summaries of complex eligibility criteria
  - "Talk to Your Doctor" prep sheet generator
  - Q&A chatbot: "Can I join this trial if I had surgery last year?"

- **Epic: Conversational Search**
  - Allow users to describe situation in natural language
  - Extract entities (conditions, location, preferences)
  - Run search and explain why each trial was matched

**Files:**
- `app/services/ai/trial_explainer_service.rb`
- `app/services/ai/conversational_search_service.rb`
- `app/javascript/controllers/chatbot_controller.js`

---

#### 3.2 EHR Integration (Concept)
**Effort:** 40+ hours (enterprise-level)  
**Epics:**
- **Epic: FHIR Integration**
  - Connect to patient EHR systems via FHIR API
  - Auto-populate profile with conditions, medications, lab results
  - Eligibility matching against structured EHR data

- **Epic: Provider Portal**
  - Separate interface for clinicians
  - Refer patients to trials
  - Track patient enrollment status

**Notes:** Requires HIPAA compliance, security audit, partnerships

---

#### 3.3 Researcher-Facing Features
**Effort:** 24-40 hours  
**Epics:**
- **Epic: Trial Dashboard for Sponsors**
  - Show how many users match trial criteria
  - Demographics of potential participants
  - Referral pipeline

- **Epic: Diversity Analytics**
  - Visualize trial diversity vs platform user demographics
  - Suggest trials underrepresented populations should prioritize
  - Sponsor reports on inclusivity

**Files:**
- `app/controllers/admin/trials_controller.rb`
- `app/controllers/admin/analytics_controller.rb`
- New role: `sponsor` or `researcher`

---

#### 3.4 Community Features
**Effort:** 30-50 hours  
**Epics:**
- **Epic: User Forums/Discussions**
  - Discussion boards per condition
  - Trial reviews/experiences
  - Moderation tools

- **Epic: Trial Q&A**
  - Users can ask questions about specific trials
  - Researchers or moderators can answer
  - Upvoting/downvoting

**Models:**
- Discussion, Post, Comment
- Moderation queue

---

## Summary

### Current Strengths
✅ Solid Rails foundation with modern tooling (Turbo, Stimulus, Tailwind)  
✅ Rich Profile model with comprehensive patient data  
✅ Clean API integration with ClinicalTrials.gov  
✅ Reusable ViewComponents for consistency  
✅ Onboarding flow working well  
✅ Authorization framework (Pundit) in place

### Critical Gaps (MVP Blockers)
❌ **No profile-based search** - Profile data not used in search  
❌ **No fit score** - No ranking or personalization algorithm  
❌ **No match explanation** - Users don't know why trials are shown  
❌ **No saved trials** - Bookmark feature UI-only  
❌ **No geocoding** - Can't calculate real distances  

### Technical Debt to Address
⚠️  Business logic in controller (needs SearchService)  
⚠️  Trial data as hash (needs Study PORO)  
⚠️  No API caching (performance + rate limit risk)  
⚠️  Eligibility criteria as text blob (limits matching accuracy)

### Recommended Next Steps (Priority Order)
1. **Create Study PORO** (2-4 hrs) - Foundation for all work
2. **Build FitScoreService** (8-12 hrs) - Core differentiator
3. **Integrate fit score into search** (6-8 hrs) - Make it visible
4. **Add geocoding** (4-6 hrs) - Accurate location scoring
5. **Build fit score UI components** (6-8 hrs) - Transparency & trust
6. **Add "Use My Profile" button** (4-6 hrs) - Immediate value
7. **Personalize home page** (4-6 hrs) - First impression

**Total MVP hardening effort:** ~40-50 hours (1-2 weeks)

After Phase 1, the app will have:
✅ Profile-driven search with intelligent ranking  
✅ Transparent fit scores explaining why trials match  
✅ Distance-aware location filtering  
✅ Personalized home page with recommendations  
✅ Foundation for saved trials, notifications, and AI features

This will position the app as a true **personalized clinical trial navigator** rather than a generic search interface.


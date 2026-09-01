# Trials

A clinical trial matching app. It searches ClinicalTrials.gov, scores each study
against a patient profile, and rewrites dense study text into plain language.

**Live:** https://trials-app-784f3851a3ac.herokuapp.com/

You can search without an account. Try
[`/search?condition=diabetes`](https://trials-app-784f3851a3ac.herokuapp.com/search?condition=diabetes).

## The problem

ClinicalTrials.gov holds around 500,000 studies. The search is built for
researchers. Eligibility criteria are written for clinicians. A patient trying
to find a trial they qualify for has to read study listings one at a time and
interpret medical language on their own.

This app narrows that. It takes what someone already knows about themselves,
their conditions, age, location, and how far they will travel, and turns the
public trial registry into a ranked list with the eligibility rules spelled out.

## How matching works

`TrialScorer` scores a study against a profile across six weighted criteria.

| Criterion | Weight |
|---|---|
| Conditions | 25 |
| Age | 20 |
| Sex | 20 |
| Location | 15 |
| Study type | 10 |
| Phase and risk tolerance | 10 |

Each returns 0 to 100, and the weighted total maps to a match level. Missing
profile data scores neutral rather than zero, so an incomplete profile is not
punished for what it has not filled in yet.

`EligibilityChecker` runs alongside it and builds a per-study checklist covering
age, sex, recruiting status, conditions, and parsed eligibility criteria. The
score answers how well a trial fits. The checklist answers why.

`ReadableStudySummaryGenerator` sends the study's summary and detailed
description to Claude and asks for plain prose with no medical jargon. The call
runs in a background job. The page shows a placeholder immediately and swaps in
the result over a Turbo Stream broadcast, so a slow model call never blocks a
request. Results are cached per study rather than per user, since the rewrite is
a pure function of public text.

## Architecture

```
app/services/
  clinical_trial_client.rb          ClinicalTrials.gov API v2 client
  trial_scorer.rb                   weighted multi-criteria scoring
  eligibility_checker.rb            per-study eligibility checklist
  trial_search_service.rb           search plus scoring
  trial_recommendation_service.rb   profile-driven recommendations
  readable_study_summary_generator.rb   Claude rewrite
```

Notes on a few decisions:

- **Service objects over fat models.** Every external call and every scoring
  rule lives in `app/services`, so the models stay about persistence.
- **ViewComponent for anything reused.** Cards, icons, avatars, pagination, and
  the admin stat tiles are components with their own specs.
- **Background work runs in Puma.** Solid Queue forks a supervisor, worker,
  dispatcher, and scheduler, which measured about 665MB on top of Puma's 231MB
  and does not fit a 512MB dyno. Production uses the `:async` adapter instead.
  Queued jobs are lost on restart, which is an acceptable trade for one
  user-triggered job.
- **Solid Cache and Solid Cable share the primary database.** Heroku provisions
  one database, so the four-database Rails 8 default collapses to one.

## Stack

Ruby 3.4.10, Rails 8.1, PostgreSQL. Hotwire with Turbo and Stimulus over
importmap, no build step. Tailwind CSS 4 and ViewComponent for the views. Devise
for authentication, Pundit for authorization. Solid Cache and Solid Cable.
Active Storage backed by Cloudflare R2. RSpec and FactoryBot for tests.
Deployed on Heroku.

## Running it locally

Requires Ruby 3.4.10 and PostgreSQL.

```bash
git clone https://github.com/phreeknomenal/trials.git
cd trials
bundle install

# Claude API key, used for readable study summaries
echo "ANTHROPIC_API_KEY=your-key-here" > .env

bin/rails db:prepare   # creates, loads schema, seeds lookup data
bin/dev                # http://localhost:3000
```

`db:prepare` seeds conditions, genders, races, identities, interests, and ten
placeholder testimonials. In development it also creates 29 sample users. Admin
accounts use the password `password` in development only.

Every seed is idempotent, because `seed_production` runs on each Heroku release.

```bash
bundle exec rspec       # 192 examples
bundle exec standardrb  # lint
```

## Test coverage

192 examples. Coverage is uneven and worth stating plainly. Request specs cover
authentication, authorization, the admin namespace, search, pagination, and the
landing page. The seed idempotency and pagination edge cases are well covered.

`TrialScorer` has no specs. Three of fourteen models have them. Building a
fixture set of real trial payloads is the next piece of work, because the
scoring weights cannot be tuned safely without a way to measure whether a change
helped.

## Data

Trial data comes from the [ClinicalTrials.gov API
v2](https://clinicaltrials.gov/data-api/api), a public source maintained by the
U.S. National Library of Medicine. The app stores no trial data of its own
beyond saved references and cached plain-language summaries.

Testimonials on the landing page are placeholder content for demo purposes.

## License

All rights reserved. Readable for evaluation, not licensed for use. See
[LICENSE](LICENSE).

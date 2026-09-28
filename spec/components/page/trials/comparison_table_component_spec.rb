require "rails_helper"

# The one job a comparison page has is showing what is different. The old table
# laid eleven rows out at equal weight and left the reader to find them.
RSpec.describe Page::Trials::ComparisonTableComponent, type: :component do
  let(:user) { create(:user) }

  def trial_row(**overrides)
    create(:saved_trial, {
      user: user,
      trial_title: "A study",
      study_type: "INTERVENTIONAL",
      phase: "PHASE3",
      min_age: "18 Years",
      max_age: "75 Years",
      sponsor: "Novo Nordisk",
      enrollment_count: 1240,
      trial_status: "RECRUITING",
      start_date: Date.new(2026, 3, 1),
      completion_date: Date.new(2028, 12, 1),
      status: "interested"
    }.merge(overrides))
  end

  # Keywords, not a positional hash. Under Ruby 3 a trailing hash at the call
  # site binds to the keywords, so render_pair(sponsor: "x") was reaching
  # `scored:` and raising rather than reaching the second study.
  def render_pair(scored: {}, **second_overrides)
    trials = [trial_row, trial_row(nct_id: "NCT99999999", **second_overrides)]
    render_inline(described_class.new(saved_trials: trials, scored_by_id: scored))
    trials
  end

  def row_labelled(text)
    page.all("[data-differs]").find { |r| r.text.include?(text) }
  end

  describe "marking what differs" do
    it "marks a row where the studies disagree" do
      render_pair(sponsor: "Eli Lilly")

      expect(row_labelled("Sponsor")[:"data-differs"]).to eq("true")
      expect(row_labelled("Sponsor").text).to include("DIFFERS")
    end

    it "leaves a row where they agree unmarked" do
      render_pair

      expect(row_labelled("Sponsor")[:"data-differs"]).to eq("false")
      expect(row_labelled("Sponsor").text).not_to include("DIFFERS")
    end

    # A row where two agree and the third never published the field is missing
    # data, not a difference between the studies.
    it "does not call an unpublished field a difference" do
      render_pair(phase: nil)

      expect(row_labelled("Phase")[:"data-differs"]).to eq("false")
    end

    # Two studies of the same length running in different years are the same
    # answer to "how long it runs".
    it "compares how long it runs, not when" do
      render_pair(start_date: Date.new(2027, 1, 1), completion_date: Date.new(2029, 10, 1))

      expect(row_labelled("How long it runs")[:"data-differs"]).to eq("false")
      expect(row_labelled("How long it runs").text).to include("Mar 2026")
    end
  end

  # "Active not recruiting" beside "Recruiting" beside "Enrolling by invitation"
  # is three spellings of two answers.
  describe "recruiting now" do
    it "answers yes or no rather than repeating the registry enum" do
      render_pair(trial_status: "ACTIVE_NOT_RECRUITING")

      cells = row_labelled("Recruiting now").all("div")[1..].map { |c| c.text.strip }

      expect(cells.first).to start_with("Yes")
      expect(cells.last).to start_with("No")
    end
  end

  describe "the best match pill" do
    it "marks the study that leads" do
      trials = [trial_row, trial_row(nct_id: "NCT99999999")]
      scored = {
        trials.first.id => double(total: 92, match_level: "excellent", stale?: false),
        trials.last.id => double(total: 78, match_level: "good", stale?: false)
      }

      render_inline(described_class.new(saved_trials: trials, scored_by_id: scored))

      expect(page).to have_css("article", text: "BEST MATCH", count: 1)
      expect(page.all("article").first.text).to include("BEST MATCH")
    end

    # Two studies tied on 88 have no best match between them, and saying
    # otherwise would be the page inventing a winner.
    it "names no winner when two are tied" do
      trials = [trial_row, trial_row(nct_id: "NCT99999999")]
      scored = trials.to_h { |t| [t.id, double(total: 88, match_level: "excellent", stale?: false)] }

      render_inline(described_class.new(saved_trials: trials, scored_by_id: scored))

      expect(page.text).not_to include("BEST MATCH")
    end

    it "names no winner when nothing scored" do
      render_pair

      expect(page.text).not_to include("BEST MATCH")
    end
  end

  describe "the filter control" do
    # Unchecked in the markup, checked by the controller on connect. A box that
    # renders checked while nothing filters is how a control looks broken.
    it "renders unchecked so the box and the table agree without JavaScript" do
      render_pair(sponsor: "Eli Lilly")

      expect(page).to have_css("input[type=checkbox][data-comparison-filter-target=checkbox]")
      expect(page.find("input[type=checkbox]")).not_to be_checked
    end

    it "is not offered when there is nothing to filter" do
      render_pair

      expect(page).to have_no_css("input[type=checkbox]")
      expect(page.text).to include("are the same on every row compared")
    end

    it "gives every row a group so a heading with nothing under it can hide" do
      render_pair(sponsor: "Eli Lilly")

      groups = page.all("[data-differs]").map { |r| r[:"data-group"] }

      expect(groups).to all(be_present)
      expect(page.all("[data-comparison-filter-target=heading]").length).to eq(2)
    end
  end

  # Interpolating the column count would give Tailwind a class string it never
  # sees in source, and the grid would silently collapse to one column.
  it "uses a grid template Tailwind has actually emitted" do
    render_pair

    expect(page.native.to_html).to include(described_class::COLUMN_TEMPLATES.fetch(2))
  end

  it "renders nothing with fewer than two studies" do
    render_inline(described_class.new(saved_trials: [trial_row]))

    expect(page.text.strip).to be_empty
  end
end

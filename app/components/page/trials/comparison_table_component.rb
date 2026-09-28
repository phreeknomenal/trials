# Saved studies side by side, with the rows that differ marked.
#
# The old table laid eleven rows out and left the reader to spot the
# differences themselves, which is the one job a comparison page has. Two
# studies with the same phase, the same ages and the same sponsor still
# presented every row at equal weight.
#
# The board marks a differing row and offers to hide the rest. Both are built
# here rather than in the view, because "does this row differ" is a question
# about the data and the view should only be told the answer.
class Page::Trials::ComparisonTableComponent < ApplicationComponent
  EMPTY = "—"

  # Written out rather than interpolated. Tailwind scans source for literal
  # class strings, so a template built with "repeat(#{n}, ...)" is never seen by
  # the scanner and the class is never emitted: the grid would silently fall
  # back to one column. Comparison is capped at three studies, so there are two.
  COLUMN_TEMPLATES = {
    2 => "grid-cols-[minmax(150px,190px)_minmax(0,1fr)_minmax(0,1fr)]",
    3 => "grid-cols-[minmax(150px,190px)_minmax(0,1fr)_minmax(0,1fr)_minmax(0,1fr)]"
  }.freeze

  Cell = Data.define(:text, :sub, :tone)
  Row = Data.define(:label, :cells, :differs) do
    def differs? = differs
  end
  Group = Data.define(:heading, :rows)

  attr_reader :saved_trials, :scored_by_id

  def initialize(saved_trials:, scored_by_id: {})
    @saved_trials = Array(saved_trials)
    @scored_by_id = scored_by_id || {}
  end

  def render? = saved_trials.length >= 2

  def columns = COLUMN_TEMPLATES.fetch(saved_trials.length, COLUMN_TEMPLATES.fetch(3))

  def groups
    @groups ||= [
      Group.new(heading: "What you would be doing", rows: [
        row("Study type") { |t| Cell.new(text: registry_value(t.study_type), sub: nil, tone: nil) },
        row("Phase") { |t| Cell.new(text: registry_value(t.phase), sub: nil, tone: nil) },
        row("How long it runs") { |t| duration_cell(t) },
        row("Ages taking part") { |t| Cell.new(text: age_range(t), sub: nil, tone: nil) }
      ]),
      Group.new(heading: "Who is running it", rows: [
        row("Sponsor") { |t| Cell.new(text: t.sponsor.presence || EMPTY, sub: nil, tone: nil) },
        row("People enrolling") { |t| enrollment_cell(t) },
        row("Recruiting now") { |t| recruiting_cell(t) }
      ])
    ]
  end

  def rows_that_differ = groups.flat_map(&:rows).count(&:differs?)

  # The board pills the top scorer. Only when one study actually leads: two
  # studies tied on 88 have no best match between them, and saying otherwise
  # would be the page inventing a winner.
  def best_match_id
    totals = saved_trials.filter_map { |t| [t.id, score_for(t)] if score_for(t).present? }
    return nil if totals.length < 2

    top = totals.max_by(&:last)
    return nil if totals.count { |_id, value| value == top.last } > 1

    top.first
  end

  def score_for(saved_trial) = scored_by_id[saved_trial.id]&.total

  def match_level_for(saved_trial) = scored_by_id[saved_trial.id]&.match_level

  def stale?(saved_trial) = scored_by_id[saved_trial.id]&.stale?

  private

  def row(label)
    cells = saved_trials.map { |saved_trial| yield(saved_trial) }

    Row.new(label: label, cells: cells, differs: differing?(cells))
  end

  # Only the values the registry actually gave. A row where two studies agree
  # and the third never published the field is missing data, not a difference
  # between the studies, and marking it DIFFERS would say the opposite.
  def differing?(cells)
    known = cells.map(&:text).reject { |text| text.blank? || text == EMPTY }

    known.uniq.length > 1
  end

  def registry_value(value)
    helpers.humanize_registry_value(value).presence || EMPTY
  end

  # Duration leads, as on the board, with the dates underneath it. The dates do
  # not decide whether the row differs: two studies of the same length running
  # in different years are the same answer to "how long it runs".
  def duration_cell(saved_trial)
    span = helpers.trial_duration(saved_trial.start_date, saved_trial.completion_date)
    dates = [saved_trial.start_date, saved_trial.completion_date]
      .compact.map { |d| d.strftime("%b %Y") }.uniq.join(" to ").presence

    Cell.new(text: span.presence || EMPTY, sub: dates, tone: nil)
  end

  def age_range(saved_trial)
    low = saved_trial.min_age.to_s[/\d+/]
    high = saved_trial.max_age.to_s[/\d+/]
    return EMPTY if low.blank? && high.blank?
    return "#{low} and over" if high.blank?
    return "Up to #{high}" if low.blank?

    "#{low} to #{high}"
  end

  def enrollment_cell(saved_trial)
    count = saved_trial.enrollment_count
    text = count.present? ? helpers.number_with_delimiter(count) : EMPTY

    Cell.new(text: text, sub: nil, tone: "tabular-nums")
  end

  # Yes or no rather than the registry's enum, because the reader is comparing
  # three studies and "Active not recruiting" beside "Recruiting" beside
  # "Enrolling by invitation" is three spellings of two answers.
  def recruiting_cell(saved_trial)
    value = saved_trial.trial_status
    return Cell.new(text: EMPTY, sub: nil, tone: nil) if value.blank?

    open = TrialStatus.accepting?(value)
    tone = open ? "text-good dark:text-good-on-dark font-bold" : "text-ink-2 dark:text-ink-2-on-dark"

    Cell.new(text: open ? "Yes" : "No", sub: TrialStatus.label(value), tone: tone)
  end
end

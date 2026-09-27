# What taking part actually involves, assembled only from fields the registry
# returns.
#
# The design board draws this as a timeline of one participant's journey: a
# screening visit of about three hours, a tablet daily, a clinic visit every
# three weeks, scans every twelve weeks, follow-up for two years. None of that
# is in the data and none of it can be inferred, which this project has now
# recorded four times.
#
# What the registry does give, in the order it happens to somebody taking part,
# is how they are assigned, what they receive, how long they are followed and
# when the study itself runs. That is a real sequence, so it takes the board's
# timeline form with its own stages rather than the board's invented ones.
#
# The last of those stages used to live in KeyDatesTimelineComponent, which was
# rendered nowhere: the page had a timeline of real dates sitting unused while
# this section said nothing about time at all.
class Page::Trials::TakingPartComponent < ApplicationComponent
  # Plain-language readings of the enums that carry a real consequence for the
  # person taking part. Anything not listed falls back to the humanised enum.
  PLAIN = {
    "RANDOMIZED" => "At random, not chosen by you or your doctor",
    "NON_RANDOMIZED" => "Assigned by the study team rather than at random",
    "NONE" => "Everyone knows which group they are in",
    "SINGLE" => "One side is not told which group you are in",
    "DOUBLE" => "Neither you nor the study team is told",
    "TRIPLE" => "You, the team and the assessors are not told",
    "QUADRUPLE" => "You, the team, the assessors and the analysts are not told"
  }.freeze

  # The two design fields that are not a stage in anybody's journey. They
  # describe the study's shape rather than what happens to you, so they sit
  # under the timeline instead of inside it.
  STRUCTURE_FIELDS = [
    [:design_primary_purpose, "Why it is being run"],
    [:design_intervention_model, "How the groups are arranged"]
  ].freeze

  attr_reader :study

  def initialize(study:)
    @study = study
  end

  def render? = stages.any? || structure_rows.any?

  def stages
    @stages ||= [assignment_stage, intervention_stage, follow_up_stage, running_stage].compact
  end

  def structure_rows
    @structure_rows ||= STRUCTURE_FIELDS.filter_map do |key, label|
      value = study[key].presence
      next if value.blank?

      [label, PLAIN[value.to_s.upcase] || helpers.humanize_registry_value(value)]
    end
  end

  def interventions = Array(study[:interventions]).select { |i| i[:name].present? }

  def enrollment
    return nil if study[:enrollment_count].blank?

    count = helpers.number_with_delimiter(study[:enrollment_count])
    estimated = study[:enrollment_type].to_s.casecmp?("estimated")

    estimated ? "About #{count} people expected to take part" : "#{count} people taking part"
  end

  private

  def assignment_stage
    detail = [plain(study[:design_allocation]), plain(study[:design_masking])].compact_blank
    return nil if detail.empty?

    {label: "How you are assigned", detail: "#{detail.join(". ")}."}
  end

  def intervention_stage
    return nil if interventions.empty?

    {label: "What you would receive", interventions: interventions}
  end

  # Outcome time frames are the closest the registry comes to saying how long
  # this runs for. They are the study's own words, so they are quoted rather
  # than parsed into a duration the app would be inventing.
  def follow_up_stage
    frames = Array(study[:primary_outcomes]).filter_map { |o| o[:time_frame].presence }.uniq.first(3)
    return nil if frames.empty?

    {label: "How long they follow you", detail: frames.join(" · "), aside: "The study's own wording."}
  end

  def running_stage
    return nil if date_range.blank?

    {label: "When the study runs", detail: date_range}
  end

  def date_range
    from = helpers.registry_date(study[:start_date])
    to = helpers.registry_date(study[:completion_date])
    return nil if from.blank? && to.blank?
    return "Started #{from}" if to.blank?
    return "Runs until #{to}" if from.blank?

    "#{from} to #{to}"
  end

  # "NA" is how the registry says a single-group study has no allocation. Read
  # through humanize_registry_value it becomes "Not applicable", and "How you
  # are assigned: Not applicable" is a line that costs a reader time and tells
  # them nothing.
  def plain(value)
    return nil if value.blank? || value.to_s.strip.casecmp?("na")

    PLAIN[value.to_s.upcase] || helpers.humanize_registry_value(value).presence
  end
end

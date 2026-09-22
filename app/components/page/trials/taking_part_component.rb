# What taking part actually involves, assembled only from fields the registry
# returns.
#
# The design board draws a visit schedule: a screening visit of about three
# hours, a tablet daily, clinic every three weeks, scans every twelve weeks. None
# of that is in the data and none of it can be inferred. What the registry does
# give is the design, the interventions and the outcome time frames, which
# together answer the same question less precisely and truthfully.
class Page::Trials::TakingPartComponent < ApplicationComponent
  # The registry's design enums, in the order someone reads them: what happens to
  # me, then how I am assigned, then who knows which group I am in.
  DESIGN_FIELDS = [
    [:design_primary_purpose, "Why the study is being run"],
    [:design_intervention_model, "How the groups are arranged"],
    [:design_allocation, "How you are assigned"],
    [:design_masking, "Who knows which group you are in"]
  ].freeze

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

  attr_reader :study

  def initialize(study:)
    @study = study
  end

  def render? = design_rows.any? || interventions.any? || time_frames.any?

  def design_rows
    @design_rows ||= DESIGN_FIELDS.filter_map do |key, label|
      value = study[key].presence
      next if value.blank?

      [label, PLAIN[value.to_s.upcase] || helpers.humanize_registry_value(value)]
    end
  end

  def interventions = Array(study[:interventions]).select { |i| i[:name].present? }

  # Outcome time frames are the closest the registry comes to saying how long
  # this runs for. They are the study's own words, so they are quoted rather
  # than parsed into a duration the app would be inventing.
  def time_frames
    @time_frames ||= Array(study[:primary_outcomes])
      .filter_map { |o| o[:time_frame].presence }
      .uniq
      .first(3)
  end

  def enrollment
    return nil if study[:enrollment_count].blank?

    count = number_with_delimiter(study[:enrollment_count])
    estimated = study[:enrollment_type].to_s.casecmp?("estimated")

    estimated ? "About #{count} people expected to take part" : "#{count} people taking part"
  end
end

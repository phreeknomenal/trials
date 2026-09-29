class TrialSearchService
  DEFAULT_PAGE_SIZE = 10

  # The registry's search takes a condition and a location and nothing else: no
  # phase, no study type, no distance radius, and no facet counts. So any
  # refinement beyond those two has to happen here, over a batch we have already
  # fetched.
  #
  # That is why a refined search pulls 100 and paginates in Ruby. Filtering a
  # page of 10 would leave three results on page one and seven on page two,
  # since the registry does not know what was filtered out.
  BATCH_SIZE = 100

  FILTERABLE = %i[phase study_type].freeze

  def initialize(profile:, search_params:, page: 1, page_size: DEFAULT_PAGE_SIZE, page_token: nil, filters: {})
    @profile = profile
    @search_params = search_params
    @page = page
    @page_size = page_size
    @page_token = page_token
    @filters = (filters || {}).symbolize_keys
  end

  def search(sort_by: nil)
    if refined?(sort_by)
      refined_search(sort_by)
    else
      standard_search
    end
  end

  private

  attr_reader :filters

  def refined?(sort_by)
    sort_by == "score" || active_filters.any? || hide_ineligible?
  end

  def active_filters
    FILTERABLE.index_with { |key| Array(filters[key]).compact_blank }.reject { |_, v| v.empty? }
  end

  def hide_ineligible? = ActiveModel::Type::Boolean.new.cast(filters[:hide_ineligible]).present?

  def typed_location = @search_params[:location].presence

  def typed_zip
    return @typed_zip if defined?(@typed_zip)

    @typed_zip = ZipCode.lookup(typed_location)
  end

  # The registry's own search does not understand postal codes. query.locn is a
  # place-name match, so "35203" returns nothing at all while "Birmingham,
  # Alabama" returns four, and the field has invited a zip since it was written.
  #
  # So a typed zip is translated into the town it names, which is what the
  # reader meant and what the registry can answer.
  def resolved_location
    return typed_location if typed_zip.nil?
    return nil if within_miles.present?

    [typed_zip.city, typed_zip.state].compact_blank.join(", ")
  end

  # Where a radius is measured from.
  #
  # A typed zip wins: someone searching 60601 while living in Birmingham means
  # Chicago. A typed place name anchors nothing — the lookup holds postal codes,
  # not town names — and measuring their radius from the profile instead would
  # silently answer a different question, fifty miles from Birmingham for a
  # search that said Chicago. It reports that it could not be anchored.
  def origin
    return @origin if defined?(@origin)

    @origin = if typed_zip
      typed_zip.coordinates
    elsif typed_location
      nil
    else
      @profile&.coordinates
    end
  end

  def within_miles = @search_params[:within_miles].presence

  # True when a radius was asked for and there was no point to measure it from,
  # so the page can say so instead of quietly returning the whole registry.
  def radius_unanchored? = within_miles.present? && origin.blank?

  # A radius that resolved replaces the location rather than joining it: the
  # registry ANDs its filters, so sending both would narrow a zip search to the
  # studies inside the radius *and* matching the town's name.
  def registry_arguments
    @search_params
      .except(:within_miles, :location)
      .merge(location: resolved_location, within_miles: within_miles, origin: origin)
      .compact
  end

  def standard_search
    result = ClinicalTrialClient.advanced_search(
      **registry_arguments, page_token: @page_token, page_size: @page_size
    )

    studies = score_studies(result[:studies] || [])

    {
      studies: studies,
      total_count: result[:total_count],
      error: result[:error],
      current_page: @page,
      has_next_page: result[:next_page_token].present?,
      next_page_token: result[:next_page_token],
      facets: facets_for(studies),
      refined: false,
      radius_unanchored: radius_unanchored?
    }
  end

  def refined_search(sort_by)
    result = ClinicalTrialClient.advanced_search(
      # Always from the beginning, so the batch being refined is the same batch
      # whichever page is being asked for.
      **registry_arguments, page_token: nil, page_size: BATCH_SIZE
    )

    scored = score_studies(result[:studies] || [])
    kept = apply_filters(scored)
    kept = kept.sort_by { |s| -(s[:trial_score] || 0) } if sort_by == "score"

    first = (@page - 1) * @page_size

    {
      radius_unanchored: radius_unanchored?,
      studies: kept[first, @page_size] || [],
      total_count: kept.length,
      error: result[:error],
      current_page: @page,
      has_next_page: first + @page_size < kept.length,
      next_page_token: nil,
      # Counted before filtering, so a filter never removes its own option from
      # the sidebar and strands whoever ticked it.
      facets: facets_for(scored),
      refined: true
    }
  end

  def apply_filters(studies)
    studies.select do |study|
      next false if hide_ineligible? && study[:match_level] == TrialScorer::INELIGIBLE

      active_filters.all? { |key, wanted| wanted.include?(study[key].to_s) }
    end
  end

  # Counts within what was fetched, which is what the sidebar has to say. They
  # are not corpus counts: the registry returns no facets, and claiming 41
  # Phase 2 studies exist when 41 is what came back in a batch of 100 would be
  # a number the app cannot stand behind.
  def facets_for(studies)
    FILTERABLE.index_with do |key|
      studies.filter_map { |s| s[key].presence }.tally.sort_by { |value, count| [-count, value] }
    end
  end

  def score_studies(studies)
    studies.map do |study|
      score_result = TrialScorer.new(@profile, study).calculate_score

      if score_result
        study.merge(
          trial_score: score_result[:total],
          score_breakdown: score_result[:breakdown],
          match_level: score_result[:match_level],
          # Carried through so a row can say which criterion rules someone out
          # rather than only greying itself down to zero. An ineligible study is
          # a hard stop from a named failure, not a low score.
          disqualifiers: score_result[:disqualifiers]
        )
      else
        study.merge(trial_score: nil, score_breakdown: nil, match_level: nil, disqualifiers: nil)
      end
    end
  end
end

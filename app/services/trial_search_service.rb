class TrialSearchService
  DEFAULT_PAGE_SIZE = 10
  SCORE_SORT_BATCH_SIZE = 100

  def initialize(profile:, search_params:, page: 1, page_size: DEFAULT_PAGE_SIZE, page_token: nil)
    @profile = profile
    @search_params = search_params
    @page = page
    @page_size = page_size
    @page_token = page_token
  end

  def search(sort_by: nil)
    if sort_by == "score"
      score_sorted_search
    else
      standard_search
    end
  end

  private

  def standard_search
    result = ClinicalTrialClient.advanced_search(
      **@search_params,
      page_token: @page_token,
      page_size: @page_size
    )

    {
      studies: score_studies(result[:studies] || []),
      total_count: result[:total_count],
      error: result[:error],
      current_page: @page,
      has_next_page: result[:next_page_token].present?,
      next_page_token: result[:next_page_token]
    }
  end

  def score_sorted_search
    # Fetch larger batch for proper global sorting
    result = ClinicalTrialClient.advanced_search(
      **@search_params,
      page_token: nil, # Always fetch from beginning for consistent sorting
      page_size: SCORE_SORT_BATCH_SIZE
    )

    all_studies = result[:studies] || []
    scored_studies = score_studies(all_studies)

    # Sort all fetched studies by score
    sorted_studies = scored_studies.sort_by { |s| -(s[:trial_score] || 0) }

    # Client-side pagination
    start_index = (@page - 1) * @page_size
    end_index = start_index + @page_size - 1
    paginated_studies = sorted_studies[start_index..end_index] || []

    {
      studies: paginated_studies,
      total_count: [ result[:total_count], SCORE_SORT_BATCH_SIZE ].min,
      error: result[:error],
      current_page: @page,
      has_next_page: end_index < sorted_studies.length - 1,
      next_page_token: nil # Not used in score sorting
    }
  end

  def score_studies(studies)
    studies.map do |study|
      scorer = TrialScorer.new(@profile, study)
      score_result = scorer.calculate_score

      if score_result
        study.merge(
          trial_score: score_result[:total],
          score_breakdown: score_result[:breakdown],
          match_level: score_result[:match_level]
        )
      else
        study.merge(
          trial_score: nil,
          score_breakdown: nil,
          match_level: nil
        )
      end
    end
  end
end

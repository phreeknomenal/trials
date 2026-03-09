class TrialRecommendationService
  DEFAULT_RECOMMENDATION_COUNT = 5
  RECOMMENDATION_BATCH_SIZE = 100
  MINIMUM_SCORE_THRESHOLD = 60
  REQUEST_TIMEOUT = 5 # seconds

  def initialize(profile)
    @profile = profile
  end

  def recommend
    return [] unless @profile

    begin
      Timeout.timeout(REQUEST_TIMEOUT) do
        fetch_and_score_trials
      end
    rescue Timeout::Error, StandardError => e
      Rails.logger.error("Error generating trial recommendations: #{e.class} - #{e.message}")
      []
    end
  end

  private

  def fetch_and_score_trials
    # Determine primary condition
    primary_condition = @profile.conditions.first&.name
    return [] unless primary_condition

    # Search for trials using primary condition
    result = ClinicalTrialClient.advanced_search(
      condition: primary_condition,
      page_size: RECOMMENDATION_BATCH_SIZE
    )

    studies = result[:studies] || []
    return [] if studies.empty?

    # Filter and score trials
    scored_trials = score_trials(studies)

    # Filter by minimum score and recruiting status
    recommended = scored_trials.select do |trial|
      trial[:trial_score] && trial[:trial_score] >= MINIMUM_SCORE_THRESHOLD &&
        is_actively_recruiting?(trial)
    end

    # Sort by score and return top N
    recommended
      .sort_by { |t| -(t[:trial_score] || 0) }
      .take(DEFAULT_RECOMMENDATION_COUNT)
  end

  def score_trials(studies)
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

  def is_actively_recruiting?(trial)
    recruiting_statuses = ["recruiting", "active, not recruiting", "enrolling by invitation"]
    status = trial[:status]&.downcase || ""
    recruiting_statuses.any? { |s| status.include?(s) }
  end
end

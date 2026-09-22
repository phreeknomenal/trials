class TrialRecommendationService
  # Five outcomes used to be one empty array, so the dashboard could not tell
  # "nothing matches you" from "the registry did not answer", and said the
  # former in both cases. They need different words and different next steps:
  # one is a fact about the studies, the other is a fact about our request.
  #
  # The client's own :error was discarded entirely, so a failed search looked
  # exactly like a successful search for something that does not exist.
  Result = Data.define(:studies, :status) do
    def any? = studies.any?

    def ok? = status == :ok

    # Worth telling apart in the view: these two are the person's to fix.
    def needs_profile? = status == :no_profile || status == :no_condition

    # Ours to fix, and worth saying so rather than implying the registry is
    # empty.
    def unavailable? = status == :unavailable

    def none_matched? = status == :none_matched
  end

  DEFAULT_RECOMMENDATION_COUNT = 5
  RECOMMENDATION_BATCH_SIZE = 100
  MINIMUM_SCORE_THRESHOLD = 60
  REQUEST_TIMEOUT = 5 # seconds

  def initialize(profile)
    @profile = profile
  end

  def recommend
    return Result.new(studies: [], status: :no_profile) unless @profile

    Timeout.timeout(REQUEST_TIMEOUT) do
      fetch_and_score_trials
    end
  rescue => e
    # Still rescued, because a dashboard that raises because a third party is
    # slow is worse than one that says so. What changed is that it says so.
    Rails.logger.error("Error generating trial recommendations: #{e.class} - #{e.message}")
    Result.new(studies: [], status: :unavailable)
  end

  # Returns trials similar to the given study (same condition, excluded nct_id), scored for profile.
  def similar_to_study(study, exclude_nct_id:, limit: 5)
    return [] unless @profile && study.present? && exclude_nct_id.present?

    condition = study[:conditions]&.first
    condition = condition.is_a?(Hash) ? condition[:name] : condition
    condition = condition.presence || @profile.conditions.first&.name
    return [] unless condition.present?

    begin
      Timeout.timeout(REQUEST_TIMEOUT) do
        result = ClinicalTrialClient.advanced_search(
          condition: condition,
          page_size: RECOMMENDATION_BATCH_SIZE
        )
        studies = result[:studies] || []
        studies = studies.reject { |s| s[:nct_id].to_s == exclude_nct_id.to_s }
        scored = score_trials(studies)
        scored
          .select { |t| t[:trial_score].present? && is_actively_recruiting?(t) }
          .sort_by { |t| -(t[:trial_score] || 0) }
          .take(limit)
      end
    rescue => e
      Rails.logger.error("Error generating similar trials: #{e.class} - #{e.message}")
      []
    end
  end

  private

  def fetch_and_score_trials
    primary_condition = @profile.conditions.first&.name
    return Result.new(studies: [], status: :no_condition) if primary_condition.blank?

    result = ClinicalTrialClient.advanced_search(
      condition: primary_condition,
      page_size: RECOMMENDATION_BATCH_SIZE
    )

    # The client rescues its own failures into an :error key rather than
    # raising, so this is the only place a failed request can be noticed.
    return Result.new(studies: [], status: :unavailable) if result[:error].present?

    recommended = score_trials(result[:studies] || []).select do |trial|
      trial[:trial_score] && trial[:trial_score] >= MINIMUM_SCORE_THRESHOLD &&
        is_actively_recruiting?(trial)
    end

    studies = recommended.sort_by { |t| -(t[:trial_score] || 0) }.take(DEFAULT_RECOMMENDATION_COUNT)

    # An empty registry response and a response where nothing scored high enough
    # are the same outcome from here: there is nothing to recommend, and it is
    # not because anything failed.
    Result.new(studies: studies, status: studies.any? ? :ok : :none_matched)
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

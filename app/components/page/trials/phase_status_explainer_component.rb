# frozen_string_literal: true

class Page::Trials::PhaseStatusExplainerComponent < ApplicationComponent
  # Keyed by TrialPhase's normalised vocabulary rather than this component's own,
  # so the explanation cannot disagree with the score. EARLY_PHASE1 previously
  # had no entry and fell through to the "not applicable" text, which described
  # the earliest stage of human testing as not being a trial phase at all.
  PHASE_EXPLANATIONS = {
    TrialPhase::EARLY_PHASE1 => "Early Phase 1 trials are the first human testing, usually in a very small group, to observe how the body responds.",
    TrialPhase::PHASE1 => "Phase 1 trials test safety and dosage in a small group (often 20–80 people).",
    TrialPhase::PHASE2 => "Phase 2 trials test efficacy and side effects in a larger group (100–300 people).",
    TrialPhase::PHASE3 => "Phase 3 trials compare the treatment to standard care in large groups (300–3,000+ people).",
    TrialPhase::PHASE4 => "Phase 4 trials happen after approval to monitor long-term safety in the general population.",
    TrialPhase::NOT_APPLICABLE => "Not applicable (e.g., behavioral or device studies may not use phase labels)."
  }.freeze

  STATUS_EXPLANATIONS = {
    "recruiting" => "This trial is actively looking for participants. You can contact the study team to see if you qualify.",
    "active, not recruiting" => "The trial is ongoing but not enrolling new participants. You may still be able to join in some cases.",
    "enrolling by invitation" => "Participants are selected by the study team. You cannot sign up directly.",
    "completed" => "The trial has finished. Results may be available on ClinicalTrials.gov.",
    "not yet recruiting" => "The trial is approved but not yet open for enrollment. Check back later.",
    "suspended" => "The trial has been paused. It may or may not resume.",
    "terminated" => "The trial was stopped early and will not continue.",
    "withdrawn" => "The trial was withdrawn before enrolling participants."
  }.freeze

  def initialize(phase: nil, status: nil)
    @phase = phase
    @status = status
  end

  # Explains the least-tested phase a trial names, matching how TrialScorer
  # weighs it. A PHASE1, PHASE2 study is described as phase 1 because that is
  # the risk the participant actually takes on.
  def phase_key
    return nil if TrialPhase.blank?(@phase)
    return TrialPhase::NOT_APPLICABLE if TrialPhase.not_applicable?(@phase)

    TrialPhase.lowest(@phase) || TrialPhase::NOT_APPLICABLE
  end

  def phase_explanation
    PHASE_EXPLANATIONS[phase_key]
  end

  def status_key
    return nil if @status.blank?

    STATUS_EXPLANATIONS.keys.find { |k| @status.to_s.downcase.include?(k) }
  end

  def status_explanation
    STATUS_EXPLANATIONS[status_key]
  end

  def render?
    phase_explanation.present? || status_explanation.present?
  end
end

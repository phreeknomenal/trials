require "rails_helper"

RSpec.describe TrialStatus, ".accepting?" do
  # The bug this exists for: `advanced_search` sent a condition and a location
  # and no status, so the registry returned everything it held. Measured against
  # the live API across four conditions, 100 results each:
  #
  #   asthma    10/100 recruiting, 62 completed
  #   leukemia  14/100 recruiting, 42 completed
  #   diabetes   8/100 recruiting, 72 completed
  #   migraine   6/100 recruiting, 57 completed
  #
  # Between 86% and 94% of what a patient saw was a study they could not join,
  # scored and ranked as though they could.
  describe "what a search asks for" do
    it "accepts the statuses a person can act on today" do
      %w[RECRUITING NOT_YET_RECRUITING ENROLLING_BY_INVITATION AVAILABLE].each do |status|
        expect(described_class).to be_accepting(status)
      end
    end

    it "refuses the ones that had been filling the results page" do
      %w[COMPLETED TERMINATED WITHDRAWN SUSPENDED].each do |status|
        expect(described_class).not_to be_accepting(status)
      end
    end

    # The two lists answer different questions. PENDING asks whether a status
    # should count against a study, and a running study can reopen, so it does
    # not. ACCEPTING asks whether the person can do anything about it today, and
    # for a study running with enrolment closed the answer is no.
    it "excludes a study that is running but closed to new participants" do
      expect(described_class).to be_pending("ACTIVE_NOT_RECRUITING")
      expect(described_class).not_to be_accepting("ACTIVE_NOT_RECRUITING")
    end

    # The module's own warning, now that a second list can trip over it:
    # "ACTIVE_NOT_RECRUITING" contains "RECRUITING" and "NOT_YET_RECRUITING"
    # does too, so any substring match here is wrong.
    it "matches exactly rather than by substring" do
      expect(described_class.normalize("Active, not recruiting")).to eq("active_not_recruiting")
      expect(described_class).not_to be_accepting("Active, not recruiting")
    end

    it "does not accept an unknown status" do
      expect(described_class).not_to be_accepting("UNKNOWN")
      expect(described_class).not_to be_accepting(nil)
    end
  end

  describe ".registry_filter" do
    it "shouts the values, because that is how the registry spells them" do
      expect(described_class.registry_filter).to eq(
        "RECRUITING|NOT_YET_RECRUITING|ENROLLING_BY_INVITATION|AVAILABLE"
      )
    end

    it "separates them with a pipe, which the API reads as OR" do
      expect(described_class.registry_filter.split("|").length).to eq(4)
    end
  end
end

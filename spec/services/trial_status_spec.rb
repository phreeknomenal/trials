require "rails_helper"

RSpec.describe TrialStatus do
  describe ".normalize" do
    it "upcases and separators into a canonical form" do
      expect(described_class.normalize("Active, not recruiting")).to eq("active_not_recruiting")
      expect(described_class.normalize("  RECRUITING  ")).to eq("recruiting")
    end
  end

  describe ".closed?" do
    %w[COMPLETED TERMINATED WITHDRAWN SUSPENDED].each do |status|
      it "treats #{status} as closed" do
        expect(described_class.closed?(status)).to be(true)
      end
    end

    %w[RECRUITING NOT_YET_RECRUITING ACTIVE_NOT_RECRUITING ENROLLING_BY_INVITATION UNKNOWN].each do |status|
      it "does not treat #{status} as closed" do
        expect(described_class.closed?(status)).to be(false)
      end
    end

    it "does not treat a missing status as closed" do
      expect(described_class.closed?(nil)).to be(false)
    end
  end

  # Substring matching is actively wrong here: ACTIVE_NOT_RECRUITING and
  # NOT_YET_RECRUITING both contain "RECRUITING".
  describe ".open?" do
    it "is true for RECRUITING" do
      expect(described_class.open?("RECRUITING")).to be(true)
    end

    it "is false for ACTIVE_NOT_RECRUITING despite containing RECRUITING" do
      expect(described_class.open?("ACTIVE_NOT_RECRUITING")).to be(false)
    end

    it "is false for NOT_YET_RECRUITING despite containing RECRUITING" do
      expect(described_class.open?("NOT_YET_RECRUITING")).to be(false)
    end
  end

  describe ".known?" do
    it "is false for an unrecognised value" do
      expect(described_class.known?("SOMETHING_NEW")).to be(false)
    end
  end
end

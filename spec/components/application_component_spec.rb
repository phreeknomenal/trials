require "rails_helper"

RSpec.describe ApplicationComponent, type: :component do
  subject(:component) { described_class.new }

  describe "match tiers" do
    # A 0-100 score is sequential data. The previous scheme used green, blue,
    # orange and red, which lost the ordering and put red against green.
    it "draws all four score tiers from one hue" do
      tiers = %w[excellent good fair poor]
      hues = tiers.map { |tier| component.match_score_text_class(tier)[/text-([a-z]+)-/, 1] }

      expect(hues.uniq).to eq(["sky"])
    end

    it "darkens the text as the score rises, so the ramp reads as an order" do
      steps = %w[poor fair good excellent].map do |tier|
        component.match_score_text_class(tier)[/text-sky-(\d+)/, 1].to_i
      end

      expect(steps).to eq(steps.sort)
    end

    it "uses no red or green anywhere in the tiers" do
      all = described_class::MATCH_TIER_STYLES.values.flat_map(&:values).join(" ")

      expect(all).not_to match(/-(red|green|orange)-/)
    end

    # Previously ineligible fell into the same else branch as poor, so a study
    # you are barred from looked identical to one that merely scores badly.
    describe "ineligible" do
      it "is not on the score ramp" do
        expect(component.match_score_text_class("ineligible")).not_to include("sky")
      end

      it "is distinguishable from poor" do
        expect(component.match_score_text_class("ineligible"))
          .not_to eq(component.match_score_text_class("poor"))
        expect(component.match_score_bg_class("ineligible"))
          .not_to eq(component.match_score_bg_class("poor"))
      end

      it "is the level TrialScorer actually emits" do
        expect(described_class::MATCH_TIER_STYLES).to have_key(TrialScorer::INELIGIBLE)
      end
    end

    describe "match_level_for" do
      {100 => "excellent", 80 => "excellent", 79 => "good", 60 => "good",
       59 => "fair", 40 => "fair", 39 => "poor", 0 => "poor"}.each do |score, tier|
        it "puts #{score} in #{tier}" do
          expect(component.match_level_for(score)).to eq(tier)
        end
      end
    end

    it "falls back to poor for a level it does not know" do
      expect(component.match_score_text_class("nonsense"))
        .to eq(component.match_score_text_class("poor"))
    end

    it "builds a badge from all three parts" do
      badge = component.match_score_badge_class(88)

      expect(badge).to include("bg-sky-100", "text-sky-800", "border", "border-sky-400")
    end
  end
end

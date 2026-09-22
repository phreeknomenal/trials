require "rails_helper"

RSpec.describe Shared::StatusBadgeComponent, type: :component do
  # The reason this exists rather than reusing Utilities::BadgeComponent: that
  # one switches on the registry's trial status, and five of these seven values
  # fell through to its default there.
  it "covers every status SavedTrial can hold" do
    expect(described_class::STATUSES.keys).to match_array(SavedTrial::STATUSES)
  end

  SavedTrial::STATUSES.each do |status|
    context status do
      before { render_inline(described_class.new(status: status)) }

      it "renders its word, so status is never colour alone" do
        expect(page.text.strip).not_to be_empty
      end

      it "carries a background so the word reads as a badge" do
        expect(page.find("span")[:class]).to match(/bg-/)
      end
    end
  end

  it "raises on a status nobody styled rather than rendering the wrong one" do
    expect { render_inline(described_class.new(status: "abandoned")) }
      .to raise_error(ArgumentError, /Unknown status/)
  end

  # The four pipeline states are sequential data: one hue, light to dark, with
  # enrolled taking the good token because arriving there is the outcome.
  it "runs the pipeline as one hue and leaves the terminal states off it" do
    pipeline = %w[applying contacted].map { |s| described_class::STATUSES[s][:classes] }

    expect(pipeline).to all(match(/sky/))
    expect(described_class::STATUSES["enrolled"][:classes]).to match(/good/)
    expect(described_class::STATUSES["rejected"][:classes]).to match(/crit/)
  end

  it "gives the states that carry meaning an icon as well as a colour" do
    %w[enrolled rejected not_eligible completed].each do |status|
      expect(described_class::STATUSES[status][:icon]).to be_present
    end
  end
end

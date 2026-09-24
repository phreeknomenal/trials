require "rails_helper"

RSpec.describe Faq do
  describe "structure" do
    it "files every entry under a category the page renders" do
      described_class.entries.each do |entry|
        expect(described_class.categories).to include(entry.category)
      end
    end

    it "leaves no category empty" do
      described_class.categories.each do |category|
        expect(described_class.for_category(category)).not_to be_empty
      end
    end

    it "asks each question once" do
      questions = described_class.entries.map(&:question)

      expect(questions.uniq.size).to eq(questions.size)
    end

    it "gives every answered entry an answer, and every unanswered one none" do
      described_class.entries.each do |entry|
        if entry.unanswered?
          expect(entry.answer).to be_nil, "#{entry.question} is marked unanswered but has an answer"
        else
          expect(entry.answer).to be_present, "#{entry.question} has no answer and is not marked unanswered"
        end
      end
    end
  end

  # Six of the twelve answers on the design board described features the app
  # does not have: a placebo flag on every listing, a visit schedule, what
  # insurance covers, a filter for travel reimbursement, and an automatic record
  # of which study teams replied. They read as fact because they are prose
  # rather than numbers, which makes them harder to spot than an invented figure,
  # not easier.
  #
  # These are proxies. They catch the exact sentences that were wrong coming
  # back, not every possible new one, and that is worth saying plainly.
  describe "claims the app cannot back" do
    let(:answers) { described_class.entries.filter_map(&:answer).join(" ") }

    it "does not promise a visit schedule the registry does not publish" do
      expect(answers).not_to match(/visit schedule is on the study page/i)
    end

    it "does not claim a listing says what insurance covers" do
      expect(answers).not_to match(/each listing says what that study covers/i)
    end

    it "does not offer a filter for travel reimbursement" do
      expect(answers).not_to match(/you can filter for it/i)
    end

    it "does not claim every listing flags a placebo group" do
      expect(answers).not_to match(/every listing says whether there is a placebo/i)
    end

    it "does not claim saved studies track who replied" do
      expect(answers).not_to match(/track who has answered/i)
    end

    it "quotes no turnaround time for a study team, since we cannot know one" do
      expect(answers).not_to match(/within a week/i)
    end

    # The app does have a filter sidebar, and it filters two things. Naming the
    # two it really has is the antidote to describing ones it does not.
    it "only claims filters the search service actually implements" do
      expect(TrialSearchService::FILTERABLE).to contain_exactly(:phase, :study_type)
    end
  end

  # Account deletion is on account settings, not the profile page, which is
  # where the board put it. Sending someone to the wrong page to delete their
  # health data is how they conclude the feature does not exist.
  describe "pointing at controls that exist" do
    it "sends people to account settings to delete everything" do
      entry = described_class.entries.find { |e| e.question.include?("delete everything") }

      expect(entry.answer).to match(/account settings/i)
      expect(entry.answer).not_to match(/from your profile page/i)
    end
  end

  describe "what is still open" do
    it "leaves exactly the funding question unanswered" do
      expect(described_class.unanswered.map(&:question)).to eq(["Does Dira Health cost anything?"])
    end
  end
end

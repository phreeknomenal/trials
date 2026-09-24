require "rails_helper"

RSpec.describe PrivacyInventory do
  # The whole reason this file exists.
  #
  # A privacy policy is the one page in an app that goes stale silently and
  # harmfully. Add a column to `profiles` and nothing breaks, nothing warns, and
  # the page keeps telling patients we hold one thing while we hold another.
  #
  # This is the same guard as the profile-sections spec from PR 7, which asserts
  # no profile field lands in no section. There the cost of drift was a field
  # nobody could edit. Here it is a statement to patients that is no longer true.
  describe "coverage against the schema" do
    it "accounts for every column on every model holding personal data" do
      expect(described_class.unlisted).to eq({}),
        -> {
          described_class.unlisted.map { |model, columns|
            "#{model} has #{columns.join(", ")} in no privacy entry. Add them to an entry in " \
            "PrivacyInventory::ENTRIES, or to INTERNAL with a reason they are not personal."
          }.join("\n")
        }
    end

    it "names no column that has since been renamed away" do
      expect(described_class.phantom).to eq({}),
        -> {
          described_class.phantom.map { |model, columns|
            "The privacy policy describes #{model}.#{columns.join(", ")}, which no longer exists."
          }.join("\n")
        }
    end

    it "covers the models that actually hold something about a person" do
      expect(described_class::COVERED_MODELS).to include("User", "Profile", "SavedTrial", "ContactMessage")
    end
  end

  describe "the entries themselves" do
    it "gives every entry a title, an example and a collection moment" do
      described_class.entries.each do |entry|
        expect(entry.title).to be_present
        expect(entry.examples).to be_present
        expect(entry.collected_when).to be_present
      end
    end

    it "puts every entry against a model it is checked for" do
      names = described_class.entries.map(&:model_name).uniq

      expect(names - described_class::COVERED_MODELS).to be_empty
    end

    # An entry with neither a column nor an extra is a row of prose describing
    # nothing, which is how a policy drifts into saying what someone wished were
    # true rather than what the database holds.
    it "backs every entry with at least one column or one named extra" do
      described_class.entries.each do |entry|
        expect(entry.columns.any? || entry.extras.any?)
          .to be(true), "#{entry.title} names no column and no extra"
      end
    end
  end

  # The exemptions are the loophole. Left ungoverned, the easy fix for a failing
  # coverage spec is to drop the new column into INTERNAL, which is exactly how
  # the check would stop doing its job.
  describe "the internal exemptions" do
    it "gives a reason for every exempted column" do
      described_class::INTERNAL.each do |column, reason|
        expect(reason).to be_present, "#{column} is exempt with no reason given"
      end
    end

    it "exempts nothing that sounds like information about a person" do
      suspicious = described_class::INTERNAL.keys.grep(/name|email|phone|address|zip|birth|dob|gender|race|ethnic/i)

      expect(suspicious).to be_empty
    end
  end
end

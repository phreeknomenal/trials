require "rails_helper"

RSpec.describe Seeds::Builder do
  subject(:builder) { described_class.new }

  describe "#seed_development" do
    it "creates the seeded users" do
      builder.seed_development

      expect(User.count).to be_positive
    end

    # Previously used Faker::Internet.email, so every run created 25 more
    # members -- development reached 79 users from repeated seeding.
    it "is idempotent across repeated runs" do
      builder.seed_development
      after_first = User.count

      builder.seed_development
      builder.seed_development

      expect(User.count).to eq(after_first)
    end

    it "does not duplicate profiles either" do
      builder.seed_development
      after_first = Profile.count

      builder.seed_development

      expect(Profile.count).to eq(after_first)
    end
  end
end

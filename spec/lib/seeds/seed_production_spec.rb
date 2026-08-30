require "rails_helper"

# seed_production runs on every Heroku release via the Procfile. A seed that is
# not idempotent would duplicate its records on each deploy, growing without
# bound. This spec is the guard on that.
RSpec.describe Seeds::Builder do
  subject(:builder) { described_class.new }

  def counts
    {
      genders: Gender.count,
      races: Race.count,
      identities: Identity.count,
      interests: Interest.count,
      conditions: Condition.count,
      testimonials: Testimonial.count
    }
  end

  describe "#seed_production" do
    it "creates the lookup tables and testimonials" do
      builder.seed_production

      expect(counts.values).to all(be_positive)
    end

    it "creates no users" do
      builder.seed_production

      expect(User.count).to eq(0)
    end

    it "is idempotent across repeated runs" do
      builder.seed_production
      after_first = counts

      builder.seed_production
      builder.seed_production

      expect(counts).to eq(after_first)
    end
  end
end

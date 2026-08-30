require "rails_helper"

RSpec.describe Seeds::Record::Testimonial do
  describe ".seed" do
    before { described_class.seed }

    it "creates ten testimonials" do
      expect(Testimonial.count).to eq(10)
    end

    it "marks every seeded record as a placeholder" do
      expect(Testimonial.placeholder.count).to eq(10)
    end

    it "publishes them so they render" do
      expect(Testimonial.published.count).to eq(10)
    end

    it "assigns distinct positions so ordering is stable" do
      positions = Testimonial.pluck(:position)

      expect(positions.uniq.length).to eq(10)
    end

    it "creates valid records" do
      expect(Testimonial.all).to all(be_valid)
    end
  end

  # seed_production runs on every Heroku release via the Procfile's db:prepare,
  # so a non-idempotent seed would duplicate all ten on each deploy.
  describe "run twice" do
    it "does not duplicate records" do
      described_class.seed
      described_class.seed

      expect(Testimonial.count).to eq(10)
    end

    it "leaves non-placeholder testimonials untouched" do
      real = create(:testimonial, author_name: "A Real Person")

      described_class.seed
      described_class.seed

      expect(real.reload.placeholder).to be(false)
      expect(Testimonial.placeholder.count).to eq(10)
    end
  end
end

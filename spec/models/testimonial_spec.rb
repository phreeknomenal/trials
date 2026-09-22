require "rails_helper"

# == Schema Information
#
# Table name: testimonials
#
#  id          :bigint           not null, primary key
#  author_name :string           not null
#  author_role :string
#  placeholder :boolean          default(FALSE), not null
#  position    :integer          default(0), not null
#  published   :boolean          default(FALSE), not null
#  quote       :text             not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_testimonials_on_published_and_position  (published,position)
#
RSpec.describe Testimonial, type: :model do
  subject { build(:testimonial) }

  describe "validations" do
    it { is_expected.to validate_presence_of(:quote) }
    it { is_expected.to validate_presence_of(:author_name) }

    it "is valid with a quote and an author_name" do
      expect(build(:testimonial)).to be_valid
    end
  end

  describe ".published" do
    it "includes published records" do
      published = create(:testimonial)

      expect(described_class.published).to include(published)
    end

    it "excludes unpublished records" do
      unpublished = create(:testimonial, :unpublished)

      expect(described_class.published).not_to include(unpublished)
    end

    it "defaults published to false on a new record" do
      expect(described_class.new.published).to be(false)
    end
  end

  describe ".placeholder" do
    it "includes seeded placeholder records" do
      placeholder = create(:testimonial, :placeholder)

      expect(described_class.placeholder).to include(placeholder)
    end

    it "excludes real records" do
      real = create(:testimonial)

      expect(described_class.placeholder).not_to include(real)
    end

    it "defaults placeholder to false on a new record" do
      expect(described_class.new.placeholder).to be(false)
    end
  end

  describe ".ordered" do
    it "orders by position ascending" do
      second = create(:testimonial, position: 2)
      first = create(:testimonial, position: 1)

      expect(described_class.ordered.to_a).to eq([first, second])
    end

    it "breaks position ties by id so the order is deterministic" do
      earlier = create(:testimonial, position: 5)
      later = create(:testimonial, position: 5)

      expect(described_class.ordered.to_a).to eq([earlier, later])
    end
  end

  describe "#initials" do
    it "returns two letters for a two-word author_name" do
      expect(build(:testimonial, author_name: "Dana Whitfield").initials).to eq("DW")
    end

    it "returns a single letter for a one-word author_name" do
      expect(build(:testimonial, :single_word_name).initials).to eq("C")
    end

    it "uses only the first two words of a longer name" do
      expect(build(:testimonial, author_name: "Ana Maria Reyes Cruz").initials).to eq("AM")
    end

    it "handles extra whitespace" do
      expect(build(:testimonial, author_name: "  Dana   Whitfield  ").initials).to eq("DW")
    end

    it "returns an empty string when author_name is blank" do
      expect(build(:testimonial, author_name: "").initials).to eq("")
    end
  end

  # The bug this guards: the seeds created ten testimonials with published: true
  # and placeholder: true together, and PublicController read .published, so all
  # ten invented quotes rendered on the landing page under invented full names.
  describe ".publishable" do
    it "includes a real published record" do
      real = create(:testimonial)

      expect(described_class.publishable).to include(real)
    end

    it "excludes an unpublished record" do
      unpublished = create(:testimonial, :unpublished)

      expect(described_class.publishable).not_to include(unpublished)
    end

    it "excludes a placeholder" do
      placeholder = create(:testimonial, :placeholder)

      expect(described_class.publishable).not_to include(placeholder)
    end

    # There is deliberately no example for "a placeholder that somehow has
    # published set". The check constraint makes that row impossible to write,
    # so it cannot be set up through ActiveRecord at all. The scope still
    # excludes on both columns, because it is what any database seeded before
    # the constraint landed relies on.
  end

  describe "a placeholder can never be published" do
    it "is invalid when both are set" do
      testimonial = build(:testimonial, placeholder: true, published: true)

      expect(testimonial).not_to be_valid
      expect(testimonial.errors[:published].join).to include("cannot be turned on for a placeholder")
    end

    it "is valid as a held-back placeholder" do
      expect(build(:testimonial, :placeholder)).to be_valid
    end

    it "is refused by the database even when validations are skipped" do
      placeholder = create(:testimonial, :placeholder)

      expect { placeholder.update_column(:published, true) }
        .to raise_error(ActiveRecord::CheckViolation, /testimonials_placeholder_never_published/)
    end
  end
end

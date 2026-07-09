require "rails_helper"

RSpec.describe ReadableStudySummary, type: :model do
  subject { build(:readable_study_summary) }

  describe "validations" do
    it { is_expected.to validate_presence_of(:nct_id) }
    it { is_expected.to validate_presence_of(:status) }
    it { is_expected.to validate_uniqueness_of(:nct_id) }
    it { is_expected.to validate_inclusion_of(:status).in_array(described_class::STATUSES) }
  end

  describe "predicates" do
    it "reports pending?" do
      expect(build(:readable_study_summary).pending?).to be(true)
    end

    it "reports completed?" do
      expect(build(:readable_study_summary, :completed).completed?).to be(true)
    end

    it "reports failed?" do
      expect(build(:readable_study_summary, :failed).failed?).to be(true)
    end
  end

  describe "#stale?" do
    it "is false for a fresh pending record" do
      expect(create(:readable_study_summary).stale?).to be(false)
    end

    it "is true for a pending record older than STALE_AFTER" do
      record = create(:readable_study_summary)
      record.update_column(:updated_at, (described_class::STALE_AFTER + 1.minute).ago)

      expect(record.stale?).to be(true)
    end

    it "is false for a completed record regardless of age" do
      record = create(:readable_study_summary, :completed)
      record.update_column(:updated_at, (described_class::STALE_AFTER + 1.minute).ago)

      expect(record.stale?).to be(false)
    end
  end

  describe ".find_or_create_pending" do
    it "creates a pending record when none exists" do
      record = described_class.find_or_create_pending("NCT99999999")

      expect(record).to be_persisted
      expect(record.pending?).to be(true)
    end

    it "returns the existing record on a second call" do
      first = described_class.find_or_create_pending("NCT88888888")
      second = described_class.find_or_create_pending("NCT88888888")

      expect(second.id).to eq(first.id)
    end

    it "returns the existing record when a RecordNotUnique race occurs" do
      existing = create(:readable_study_summary, nct_id: "NCT77777777")
      allow(described_class).to receive(:find_or_create_by!).and_raise(ActiveRecord::RecordNotUnique)

      expect(described_class.find_or_create_pending("NCT77777777")).to eq(existing)
    end
  end
end

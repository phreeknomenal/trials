require "rails_helper"

RSpec.describe User, type: :model do
  describe "role predicates" do
    it "returns true from staff? for every staff role" do
      described_class::STAFF_ROLES.each do |role|
        expect(build(:user, role: role).staff?).to be(true), "expected #{role} to be staff"
      end
    end

    it "returns false from staff? for a member" do
      expect(build(:user, role: "member").staff?).to be(false)
    end

    # admin? and super_admin? are exact matches, which is why staff? exists.
    # Gating the admin namespace on admin? alone would lock out super_admins.
    it "keeps admin? as an exact role match" do
      expect(build(:user, role: "admin").admin?).to be(true)
      expect(build(:user, role: "super_admin").admin?).to be(false)
      expect(build(:user, role: "employee").admin?).to be(false)
    end

    it "keeps super_admin? as an exact role match" do
      expect(build(:user, role: "super_admin").super_admin?).to be(true)
      expect(build(:user, role: "admin").super_admin?).to be(false)
    end

    it "returns true from member? only for members" do
      expect(build(:user, role: "member").member?).to be(true)
      expect(build(:user, role: "admin").member?).to be(false)
    end
  end

  describe "scopes" do
    it "returns every staff role from .staff" do
      staff = described_class::STAFF_ROLES.map { |role| create(:user, role: role) }

      expect(described_class.staff).to match_array(staff)
    end

    it "excludes members from .staff" do
      member = create(:user, role: "member")

      expect(described_class.staff).not_to include(member)
    end

    it "returns only members from .community" do
      member = create(:user, role: "member")
      create(:user, role: "admin")

      expect(described_class.community).to contain_exactly(member)
    end
  end

  describe "ROLES" do
    it "is the union of community and staff roles" do
      expect(described_class::ROLES).to eq(described_class::COMMUNITY_ROLES + described_class::STAFF_ROLES)
    end

    it "validates role inclusion" do
      expect(build(:user, role: "wizard")).not_to be_valid
    end
  end
end

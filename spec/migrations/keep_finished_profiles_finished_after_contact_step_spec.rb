require "rails_helper"
require Rails.root.join("db/migrate/20261027190000_keep_finished_profiles_finished_after_contact_step")

RSpec.describe KeepFinishedProfilesFinishedAfterContactStep do
  def migrate_up = ActiveRecord::Migration.suppress_messages { described_class.new.migrate(:up) }

  it "keeps a profile that finished all eight earlier steps finished" do
    profile = create(:user).profile
    profile.update_columns(onboarding_step: 9)

    migrate_up

    expect(profile.reload).to be_profile_completed
  end

  it "leaves a profile partway through where it was" do
    profile = create(:user).profile
    profile.update_columns(onboarding_step: 6)

    migrate_up

    expect(profile.reload.onboarding_step).to eq(6)
  end
end

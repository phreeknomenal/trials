require "rails_helper"

RSpec.describe "Registry checks on saved studies", type: :request do
  let(:user) { create(:user) }

  before do
    sign_in user
    allow(TrialRecommendationService).to receive(:new).and_return(
      instance_double(TrialRecommendationService,
        recommend: TrialRecommendationService::Result.new(studies: [], status: :ok))
    )
  end

  {"the saved list" => -> { saved_trials_path }, "the dashboard" => -> { my_trials_root_path }}.each do |page, path|
    describe page do
      it "queues a check when a saved study is stale" do
        create(:saved_trial, user: user)

        expect { get instance_exec(&path) }
          .to have_enqueued_job(RefreshSavedTrialsJob).with(user.id)
      end

      it "queues nothing when every saved study was checked within the day" do
        create(:saved_trial, user: user, registry_checked_at: 1.hour.ago)

        expect { get instance_exec(&path) }.not_to have_enqueued_job(RefreshSavedTrialsJob)
      end

      it "queues nothing when only someone else's study is stale" do
        create(:saved_trial)

        expect { get instance_exec(&path) }.not_to have_enqueued_job(RefreshSavedTrialsJob)
      end
    end
  end
end

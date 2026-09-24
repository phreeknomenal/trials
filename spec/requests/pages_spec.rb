require "rails_helper"

RSpec.describe "Content pages", type: :request do
  # Signed out is the case that matters most. Someone weighing up whether to
  # hand over a diagnosis reads these before they have an account.
  describe "signed out" do
    it "serves about" do
      get about_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Clinical research is public")
    end

    it "serves the FAQ with every question on it" do
      get faq_path

      expect(response).to have_http_status(:ok)
      Faq.entries.each { |entry| expect(response.body).to include(ERB::Util.html_escape(entry.question)) }
    end

    it "serves the privacy policy" do
      get privacy_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("What we collect and what we do with it")
    end

    it "serves the contact form" do
      get contact_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Ask us anything about the app")
    end
  end

  # The onboarding gate redirects a half-finished account back to the wizard on
  # every HTML request. Someone who has just been asked for their conditions and
  # wants to check what happens to them would have been sent straight back to
  # the question, which is the worst possible moment to be unable to read this.
  describe "a signed-in user who has not finished onboarding" do
    let(:user) { create(:user) }

    before do
      user.profile.update!(onboarded: false, onboarding_step: 2)
      sign_in user
    end

    it "is not redirected away from the privacy policy" do
      get privacy_path

      expect(response).to have_http_status(:ok)
    end

    it "is not redirected away from the FAQ" do
      get faq_path

      expect(response).to have_http_status(:ok)
    end

    it "is not redirected away from the contact form" do
      get contact_path

      expect(response).to have_http_status(:ok)
    end

    it "is still redirected away from a page the gate exists to protect" do
      get search_index_path

      expect(response).to redirect_to(onboarding_step_path(step: user.profile.reload.current_onboarding_step.slug))
    end
  end

  # PR 5 shipped two sidebar links pointing at sections that never rendered. The
  # link worked, the click did nothing, and nothing in the suite noticed. This is
  # the same sweep, applied to the two pages here that grew an in-page nav.
  describe "in-page anchors" do
    def dangling_anchors(body)
      targets = body.scan(/href="#([^"]+)"/).flatten.uniq
      ids = body.scan(/\sid="([^"]+)"/).flatten.uniq

      targets - ids
    end

    it "has no privacy contents link pointing at a missing section" do
      get privacy_path

      expect(dangling_anchors(response.body)).to be_empty
    end

    it "has no FAQ category link pointing at a missing section" do
      get faq_path

      expect(dangling_anchors(response.body)).to be_empty
    end

    it "renders a section for every entry in the privacy contents" do
      get privacy_path

      PrivacyPolicy.sections.each do |section|
        expect(response.body).to include(%(id="#{section.slug}"))
      end
    end
  end

  # An unwritten passage has to look unwritten. The count is asserted rather than
  # the absence, because the point is that these are visible and tracked: when
  # the copy lands the number drops and this spec is what says so.
  describe "unwritten copy" do
    it "marks each unwritten privacy section rather than leaving it blank" do
      get privacy_path

      PrivacyPolicy.unwritten.each do |section|
        expect(response.body).to include("Not written yet: #{ERB::Util.html_escape(section.title.downcase)}")
      end
    end

    # Two more sit inside sections that are otherwise written: the hosting
    # provider, and how a change to the policy is announced. Counting them
    # separately is what stops either being quietly dropped.
    it "marks the two unwritten passages inside written sections" do
      get privacy_path

      expect(response.body).to include("Not written yet: the hosting provider")
      expect(response.body).to include("Not written yet: how changes are announced")
    end

    it "marks the unanswered FAQ question rather than inventing an answer" do
      get faq_path

      expect(response.body.scan("Not written yet:").count).to eq(Faq.unanswered.count)
    end

    it "says on the privacy policy how many sections are outstanding" do
      get privacy_path

      expect(response.body).to include("#{PrivacyPolicy.unwritten.count} of the #{PrivacyPolicy.sections.count} sections")
    end
  end

  # Every number on the design boards was invented, and prose carries the same
  # risk less visibly. These are the two the boards asserted.
  describe "claims the app cannot back" do
    it "does not promise a reply within any number of days" do
      get contact_path

      expect(response.body).not_to match(/within (two|2|three|3) working days/i)
    end

    it "does not claim most study teams respond within a week" do
      get faq_path

      expect(response.body).not_to match(/respond within a week/i)
    end
  end
end

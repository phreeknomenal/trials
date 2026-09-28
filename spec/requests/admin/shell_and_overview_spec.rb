require "rails_helper"

# The admin chrome was in no PR of the design plan. Four boards draw the same
# bar and the plan covered two screens, so the two rebuilt in PR 14 shipped
# under an amber warning band the boards replaced with a dark navy one.
RSpec.describe "The admin shell and overview", type: :request do
  let(:staff) { create(:user, role: "admin") }

  before { sign_in staff }

  describe "the bar" do
    # On every admin page, so it is asserted on more than one.
    %w[/admin /admin/users /admin/testimonials /admin/operations /admin/contact_messages].each do |path|
      it "carries the mark and the admin pill on #{path}" do
        get path

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("ADMIN")
        expect(response.body).to include("bg-surface-on-dark")
      end
    end

    it "marks the page you are on, and only that one" do
      get admin_users_path

      current = Nokogiri::HTML(response.body).css("nav[aria-label=Admin] a[aria-current=page]")

      expect(current.map { |a| a.text.strip }).to eq(["Users"])
    end

    # Not on the boards: admin/contact_messages did not exist when they were
    # drawn, and PR #147 added it.
    it "keeps the messages queue the boards do not have" do
      get admin_root_path

      expect(response.body).to include("Messages")
      expect(response.body).to include(admin_contact_messages_path)
    end

    # The controller applies the dark class on connect, and no admin page
    # mounted it, so admin ignored the reader's theme and rendered light
    # whatever they had chosen. PR 11 swept every page for dark and missed this.
    it "gives admin the reader's theme, and a way to change it" do
      get admin_root_path

      expect(response.body).to include('data-controller="dark-mode"')
      expect(response.body).to include("Toggle dark mode")
    end

    # The bar is navy in light mode too, so an ink-2 glyph on it is a dark grey
    # on near-black: the invisible control ButtonStyles already records once.
    it "renders that toggle in a colour visible on a permanently dark bar" do
      get admin_root_path

      toggle = response.body[/<div data-controller="dark-mode">.*?<\/div>/m].to_s

      expect(toggle).to include("text-ink-3-on-dark")
      expect(toggle).not_to match(/class="w-5 h-5 text-ink-2[ "]/)
    end

    # The boards drop it. Knowing which account you are acting as matters more
    # here than anywhere else in the app.
    it "keeps saying which account is acting" do
      get admin_root_path

      expect(response.body).to include(staff.email)
      expect(response.body).to include(staff.role)
    end
  end

  describe "the overview" do
    it "leads with four counts rather than eleven" do
      get admin_root_path

      %w[Users Profiles\ onboarded Saved\ trials Readable\ summaries].each do |label|
        expect(response.body).to include(label)
      end
    end

    # Every number is a COUNT run on request, so nothing can be quietly stale.
    it "says the counts are live" do
      get admin_root_path

      expect(response.body).to include("Counts are live. Nothing here is cached.")
    end

    it "gives the signup window its total and its rate" do
      create(:user)

      get admin_root_path

      expect(response.body).to match(/\d+ sign ups? in this window/)
      expect(response.body).to include("a day.")
    end

    # The order is the story: the pipeline falls away from interested to
    # enrolled, and sorting by status name hid that behind the alphabet.
    it "orders saved trials by count, not by name" do
      user = create(:user)
      3.times { create(:saved_trial, user: user, status: "interested") }
      create(:saved_trial, user: user, status: "applying")

      get admin_root_path

      chart = response.body[/Saved trials by status.*?<\/section>/m].to_s

      expect(chart.index("Interested")).to be < chart.index("Applying")
    end
  end
end

require "rails_helper"

RSpec.describe Layout::Navigation::TabBarComponent, type: :component do
  let(:user) { create(:user) }
  let(:profile) { user.profile }

  def signed_in(value, with_profile: nil)
    allow_any_instance_of(ApplicationComponent).to receive(:user_signed_in?).and_return(value)
    allow_any_instance_of(ApplicationComponent).to receive(:current_profile).and_return(with_profile)
  end

  describe "who sees it" do
    it "renders for a signed-in user with a profile" do
      signed_in(true, with_profile: profile)

      render_inline(described_class.new)

      expect(page).to have_css("nav[aria-label='Main']", visible: :all)
    end

    # Signed out has one task, searching, and a permanent four-tab bar would
    # spend a fifth of a 390px screen on three destinations they cannot use.
    # The slide-over panel stays for them.
    it "renders nothing for a signed-out visitor" do
      signed_in(false)

      render_inline(described_class.new)

      expect(page).to have_no_css("nav", visible: :all)
    end

    it "renders nothing without a profile, since one tab needs one" do
      signed_in(true, with_profile: nil)

      render_inline(described_class.new)

      expect(page).to have_no_css("nav", visible: :all)
    end
  end

  describe "the tabs" do
    before do
      signed_in(true, with_profile: profile)
      render_inline(described_class.new)
    end

    it "offers the four the board names" do
      expect(page.all("nav a").map { |a| a.text.strip }).to eq(["My trials", "Find", "Saved", "Profile"])
    end

    it "points each one somewhere real" do
      expect(page.all("nav a").map { |a| a[:href] }).to all(start_with("/"))
    end

    # "each a 44px target with a label". The visible content of a tab is
    # smaller than that, so without a minimum the target would be about 38px.
    it "gives every tab a 44px minimum target" do
      page.all("nav a").each do |tab|
        expect(tab[:class]).to include("min-h-11", "min-w-11")
      end
    end

    # An icon alone is a guess. The board puts a label under every one.
    it "labels every tab rather than leaving an icon to carry it" do
      page.all("nav a").each do |tab|
        expect(tab.text.strip).to be_present
        expect(tab).to have_css("svg")
      end
    end

    it "gives every tab a visible focus ring" do
      expect(page.all("nav a").map { |a| a[:class] }).to all(include("focus-visible:outline-2"))
    end
  end

  describe "where it sits" do
    before do
      signed_in(true, with_profile: profile)
      render_inline(described_class.new)
    end

    it "pins to the bottom of the viewport" do
      expect(page.find("nav", visible: :all)[:class]).to include("fixed", "bottom-0")
    end

    it "is gone above the lg breakpoint, where the top nav takes over" do
      expect(page.find("nav", visible: :all)[:class]).to include("lg:hidden")
    end

    # Without this the bar covers the last of the page, and what it covers on
    # the dashboard is the profile prompt.
    it "reserves its own height in the flow so it covers nothing" do
      expect(page).to have_css("div.h-20.lg\\:hidden[aria-hidden='true']", visible: :all)
    end
  end

  describe "the current page" do
    it "marks the tab for the page being viewed" do
      signed_in(true, with_profile: profile)

      with_request_url "/search" do
        render_inline(described_class.new)

        expect(page.find("nav a[aria-current='page']", visible: :all).text.strip).to eq("Find")
      end
    end

    it "marks nothing on a page that is not a tab" do
      signed_in(true, with_profile: profile)

      with_request_url "/about" do
        render_inline(described_class.new)

        expect(page).to have_no_css("[aria-current]", visible: :all)
      end
    end
  end
end

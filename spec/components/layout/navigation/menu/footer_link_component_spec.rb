require "rails_helper"

RSpec.describe Layout::Navigation::Menu::FooterLinkComponent, type: :component do
  # The footer used to render nine destinations as bare <li> text: About Us, Our
  # Stories, FAQ, Membership, User Policy, Customer Support, and four social
  # networks. Not one was clickable, and four named pages that did not exist.
  #
  # The rule these specs hold the file to: a footer names the places you can go.
  # Something with nowhere to point is not a quiet placeholder, it is a dead end
  # that looks like a way out.
  # Stubbed rather than signed in with Warden: a component spec runs outside the
  # middleware stack, so `user_signed_in?` has no proxy to ask.
  def signed_in(value)
    allow_any_instance_of(ApplicationComponent).to receive(:user_signed_in?).and_return(value)
  end

  describe "signed out" do
    before { signed_in(false) }

    subject(:page) { render_inline(described_class.new) }

    it "makes every entry an anchor" do
      labels = page.css("li").map { |li| li.text.strip }
      links = page.css("li a").map { |a| a.text.strip }

      expect(links).to match_array(labels)
    end

    it "gives every anchor a real href" do
      hrefs = page.css("a").map { |a| a["href"] }

      expect(hrefs).to all(be_present)
      expect(hrefs).to all(start_with("/"))
    end

    it "reaches all four content pages" do
      hrefs = page.css("a").map { |a| a["href"] }

      expect(hrefs).to include("/about", "/faq", "/privacy", "/contact")
    end

    it "offers sign in and sign up rather than account links" do
      expect(page.text).to include("Sign in", "Sign up")
      expect(page.text).not_to include("Sign out")
    end

    # Named individually because each was live text in the footer of a health
    # product, promising something the app has no route for.
    it "no longer advertises features that do not exist" do
      %w[Membership Customer\ Support Our\ Stories User\ Policy].each do |gone|
        expect(page.text).not_to include(gone)
      end
    end

    it "no longer advertises social accounts that do not exist" do
      %w[Facebook Instagram Twitter LinkedIn].each do |network|
        expect(page.text).not_to include(network)
      end
    end
  end

  describe "signed in" do
    before { signed_in(true) }

    subject(:page) { render_inline(described_class.new) }

    it "swaps the auth links for account links" do
      expect(page.text).to include("Sign out", "Account settings")
      expect(page.text).not_to include("Sign up")
    end

    it "still gives every anchor a real href" do
      expect(page.css("a").map { |a| a["href"] }).to all(be_present)
    end
  end
end

require "rails_helper"

RSpec.describe Layout::Navigation::HeaderComponent, type: :component do
  # See the menu component spec: the header renders nested components that each
  # resolve the user_signed_in? delegation on their own.
  before { allow_any_instance_of(ApplicationComponent).to receive(:user_signed_in?).and_return(false) }

  # The bug this was fixed for. Every control used to sit inside a
  # hidden lg:flex wrapper with nothing behind it, so below 1024px the header
  # rendered the wordmark and nothing else.
  describe "below the lg breakpoint" do
    it "renders a trigger that stays visible" do
      render_inline(described_class.new)

      expect(page.find("[data-mobile-menu-target='trigger']", visible: :all)[:class]).to include("lg:hidden")
    end

    it "puts the account control in the panel as well as the desktop bar" do
      render_inline(described_class.new)

      panel = page.find("#mobile-menu-panel", visible: :all)
      expect(panel).to have_link("Log in", visible: :all)
      expect(panel).to have_link("Sign up free", visible: :all)
    end

    it "puts the navigation links in the panel" do
      render_inline(described_class.new)

      panel = page.find("#mobile-menu-panel", visible: :all)
      expect(panel).to have_link("Find trials", visible: :all)
    end

    it "keeps the panel out of the accessibility tree until it is opened" do
      render_inline(described_class.new)

      expect(page).to have_css("#mobile-menu-panel[hidden]", visible: :all)
    end

    it "wires the trigger to the panel for assistive technology" do
      render_inline(described_class.new)

      trigger = page.find("[data-mobile-menu-target='trigger']", visible: :all)
      expect(trigger[:"aria-controls"]).to eq("mobile-menu-panel")
      expect(trigger[:"aria-expanded"]).to eq("false")
      expect(trigger[:"aria-label"]).to eq("Open menu")
    end
  end

  describe "the bar" do
    it "constrains with a max width rather than a viewport percentage" do
      render_inline(described_class.new)

      html = page.native.to_html
      expect(html).to include("max-w-6xl")
      expect(html).not_to include("w-[80%]")
    end

    it "renders the wordmark, not the old name" do
      render_inline(described_class.new)

      expect(page).to have_text("Dira Health")
      expect(page).to have_no_text("Lumen")
    end

    it "sets the mark beside the wordmark" do
      render_inline(described_class.new)

      expect(page).to have_css("svg.h-8", visible: :all)
    end

    it "gives the wordmark link a visible focus ring" do
      render_inline(described_class.new)

      expect(page.first("a")[:class]).to include("focus-visible:outline-2")
    end
  end

  # The header offered Login and nothing else, so the single most valuable
  # action a first-time visitor can take was reachable from the footer and from
  # nowhere else above the fold.
  describe "signed out" do
    before { render_inline(described_class.new) }

    it "offers both signing in and signing up" do
      expect(page).to have_link("Log in", href: "/users/sign_in", visible: :all)
      expect(page).to have_link("Sign up free", href: "/users/sign_up", visible: :all)
    end

    it "gives sign up the filled button and log in the quiet one" do
      signup = page.all("a", text: "Sign up free", visible: :all).first
      login = page.all("a", text: "Log in", visible: :all).first

      # Split rather than substring-matched: the quiet variant's disabled rules
      # contain "disabled:hover:bg-navy-600", so `include` passes on a button
      # that is not filled at rest.
      expect(signup[:class].split).to include("bg-navy-600")
      expect(login[:class].split).not_to include("bg-navy-600")
      expect(login[:class].split).to include("bg-transparent")
    end

    # It used to hand-roll a navy button here, which is how the header's Login
    # drifted to a different radius and hover from every other primary button.
    it "takes both buttons from the shared button styles" do
      expect(page.all("a", text: "Sign up free", visible: :all).first[:class])
        .to include("rounded-control")
    end

    it "separates navigating the site from acting on your account" do
      expect(page).to have_css("span.w-px.h-6", visible: :all)
    end
  end
end

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
      expect(panel).to have_link("Login", visible: :all)
    end

    it "puts the navigation links in the panel" do
      render_inline(described_class.new)

      panel = page.find("#mobile-menu-panel", visible: :all)
      expect(panel).to have_link("Search Trials", visible: :all)
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
end

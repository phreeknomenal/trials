require "rails_helper"

RSpec.describe Buttons::SaveTrialButtonComponent, type: :component do
  let(:base_args) { {nct_id: "NCT05812345", trial_title: "A Study of Semaglutide"} }

  def render_button(saved_trial: nil)
    render_inline(described_class.new(**base_args, saved_trial: saved_trial))
  end

  context "when the study is not saved" do
    it "announces itself as an unpressed toggle" do
      render_button

      expect(page.find("button")[:"aria-pressed"]).to eq("false")
    end

    it "shows the outline icon and hides the solid one" do
      render_button

      expect(page.find("[data-save-trial-target='outlineIcon']", visible: :all)[:class]).not_to include("hidden")
      expect(page.find("[data-save-trial-target='solidIcon']", visible: :all)[:class]).to include("hidden")
    end

    it "labels the action rather than the state" do
      render_button

      expect(page.find("[data-save-trial-target='label']").text).to eq("Save Trial")
    end
  end

  context "when the study is saved" do
    let(:saved_trial) { create(:saved_trial) }

    it "announces itself as a pressed toggle" do
      render_button(saved_trial: saved_trial)

      expect(page.find("button")[:"aria-pressed"]).to eq("true")
    end

    it "shows the solid icon and hides the outline one" do
      render_button(saved_trial: saved_trial)

      expect(page.find("[data-save-trial-target='solidIcon']", visible: :all)[:class]).not_to include("hidden")
      expect(page.find("[data-save-trial-target='outlineIcon']", visible: :all)[:class]).to include("hidden")
    end
  end

  # Both branches used to name icon partials through a method nothing called,
  # and one of those names had no partial behind it. Rendering is what proves
  # the names resolve, so both states get rendered here.
  it "renders an icon in both states" do
    render_button
    expect(page).to have_css("svg", visible: :all)

    render_button(saved_trial: create(:saved_trial))
    expect(page).to have_css("svg", visible: :all)
  end

  it "carries the state classes the Stimulus controller toggles between" do
    render_button

    expect(page.find("button")[:class]).to include("border-line-2")

    render_button(saved_trial: create(:saved_trial))

    expect(page.find("button")[:class]).to include("border-sky-500")
  end
end

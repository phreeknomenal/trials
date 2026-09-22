require "rails_helper"

# The four states from the style kit board: rest, focus, filled and error.
# Focus is a pseudo-class and filled is "rest with content in it", so what is
# testable here is rest against error, and the wiring that makes an error
# reach a screen reader.
RSpec.describe Forms::FieldComponent, type: :component do
  let(:profile) { build(:profile) }

  def render_field(object: profile, **args)
    render_inline(described_class.new(form: form_for(object), attribute: :city, **args))
  end

  # A real form builder rather than a double, because the component calls
  # text_field, select and check_box on it and a double would not catch a
  # signature change.
  def form_for(object)
    ActionView::Helpers::FormBuilder.new(
      "profile", object, vc_test_controller.view_context, {}
    )
  end

  describe "at rest" do
    it "uses the control radius from the ladder, not the 4px default" do
      render_field(label: "City")

      expect(page.find("input")[:class]).to include("rounded-control")
    end

    it "carries a visible focus treatment" do
      render_field(label: "City")

      expect(page.find("input")[:class]).to include("focus:border-focus")
    end

    it "is not marked invalid" do
      render_field(label: "City")

      expect(page.find("input")[:"aria-invalid"]).to be_nil
    end

    it "renders no error message" do
      render_field(label: "City")

      expect(page).to have_no_css("[id$='-error']")
    end
  end

  describe "in its error state" do
    let(:profile) do
      build(:profile).tap do |p|
        p.errors.add(:city, "can't be blank")
      end
    end

    it "takes the critical border" do
      render_field(label: "City")

      expect(page.find("input")[:class]).to include("border-crit")
    end

    it "drops the resting border, rather than carrying both" do
      render_field(label: "City")

      expect(page.find("input")[:class]).not_to include("border-line-2")
    end

    it "names the fix rather than only turning red" do
      render_field(label: "City")

      expect(page).to have_text("Can't be blank")
    end

    it "marks the input invalid for assistive technology" do
      render_field(label: "City")

      expect(page.find("input")[:"aria-invalid"]).to eq("true")
    end

    it "points the input at the message it belongs to" do
      render_field(label: "City")

      described_by = page.find("input")[:"aria-describedby"]

      expect(described_by).to be_present
      expect(page).to have_css("##{described_by}", text: "Can't be blank")
    end
  end

  describe "hints" do
    it "renders a hint and wires it to the input" do
      render_field(label: "City", hint: "The city you would travel from.")

      described_by = page.find("input")[:"aria-describedby"]

      expect(page).to have_css("##{described_by}", text: "The city you would travel from.")
    end

    it "points at both the hint and the error when a field has both" do
      profile.errors.add(:city, "can't be blank")

      render_field(label: "City", hint: "The city you would travel from.")

      expect(page.find("input")[:"aria-describedby"].split.length).to eq(2)
    end
  end

  describe "required fields" do
    it "marks the asterisk decorative and says the word for a screen reader" do
      render_field(label: "City", options: {required: true})

      expect(page.find("span[aria-hidden='true']").text).to eq("*")
      expect(page).to have_css(".sr-only", text: "required")
    end
  end

  # Every type has to reach the same styles, since the old component gave each
  # its own hand-written string and they drifted.
  describe "each field type" do
    {text: "input", number: "input", text_area: "textarea"}.each do |type, tag|
      it "styles #{type} from the shared field styles" do
        render_field(label: "City", field_type: type)

        expect(page.find(tag)[:class]).to include("rounded-control")
      end
    end

    it "styles select from the shared field styles" do
      render_field(label: "City", field_type: :select, select_options: [["Birmingham", "Birmingham"]])

      expect(page.find("select")[:class]).to include("rounded-control")
    end

    it "carries a select's error state too" do
      profile.errors.add(:city, "can't be blank")

      render_field(label: "City", field_type: :select, select_options: [["Birmingham", "Birmingham"]])

      expect(page.find("select")[:class]).to include("border-crit")
      expect(page.find("select")[:"aria-invalid"]).to eq("true")
    end
  end
end

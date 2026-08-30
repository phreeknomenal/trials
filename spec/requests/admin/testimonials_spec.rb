require "rails_helper"

RSpec.describe "Admin testimonials", type: :request do
  let(:admin) { create(:user, role: "admin") }

  before { sign_in admin }

  describe "GET index" do
    it "lists published and unpublished alike" do
      create(:testimonial, quote: "A published quote")
      create(:testimonial, :unpublished, quote: "A draft quote")

      get admin_testimonials_path

      expect(response.body).to include("A published quote", "A draft quote")
    end

    it "marks seeded placeholders" do
      create(:testimonial, :placeholder, author_name: "Seeded Person")

      get admin_testimonials_path

      expect(response.body).to include("Seeded")
    end

    # Icon-only controls: IconComponent renders its svg aria-hidden, so the
    # accessible name must come from the link and button themselves.
    it "renders labelled edit and delete controls" do
      create(:testimonial, author_name: "Dana Whitfield")

      get admin_testimonials_path

      expect(response.body).to include("Edit testimonial from Dana Whitfield")
      expect(response.body).to include("Delete testimonial from Dana Whitfield")
    end

    it "renders the pencil and trash icons" do
      create(:testimonial)

      get admin_testimonials_path

      expect(response.body.scan("<svg").length).to be >= 2
    end

    it "renders an empty state with no testimonials" do
      get admin_testimonials_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("No testimonials yet")
    end
  end

  describe "POST create" do
    let(:params) do
      {testimonial: {quote: "A new quote", author_name: "New Person", author_role: "Caregiver", position: 1, published: "1"}}
    end

    it "creates the testimonial" do
      expect { post admin_testimonials_path, params: params }.to change(Testimonial, :count).by(1)
    end

    it "redirects to the index" do
      post admin_testimonials_path, params: params

      expect(response).to redirect_to(admin_testimonials_path)
    end

    it "rejects a blank quote" do
      params[:testimonial][:quote] = ""

      expect { post admin_testimonials_path, params: params }.not_to change(Testimonial, :count)
      expect(response).to have_http_status(:unprocessable_content)
    end

    it "does not mark manually created records as placeholders" do
      post admin_testimonials_path, params: params

      expect(Testimonial.last.placeholder).to be(false)
    end
  end

  describe "PATCH update" do
    let(:testimonial) { create(:testimonial, quote: "Original") }

    it "edits the quote" do
      patch admin_testimonial_path(testimonial), params: {testimonial: {quote: "Revised"}}

      expect(testimonial.reload.quote).to eq("Revised")
    end

    it "toggles published" do
      patch admin_testimonial_path(testimonial), params: {testimonial: {published: "0"}}

      expect(testimonial.reload.published).to be(false)
    end
  end

  describe "DELETE destroy" do
    it "deletes the testimonial" do
      testimonial = create(:testimonial)

      expect { delete admin_testimonial_path(testimonial) }.to change(Testimonial, :count).by(-1)
    end

    # seed_production runs on every release, and the testimonial seed guards on
    # author_name -- so deleting a placeholder is undone by the next deploy.
    it "warns that deleting a placeholder is temporary" do
      placeholder = create(:testimonial, :placeholder)

      delete admin_testimonial_path(placeholder)

      expect(flash[:notice]).to match(/next deploy will recreate it/)
    end

    it "does not warn for a real testimonial" do
      delete admin_testimonial_path(create(:testimonial))

      expect(flash[:notice]).not_to match(/recreate/)
    end
  end

  describe "as a member" do
    it "is denied" do
      sign_in create(:user, role: "member")

      get admin_testimonials_path

      expect(response).to redirect_to(root_path)
    end
  end
end

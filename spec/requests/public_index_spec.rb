require "rails_helper"

RSpec.describe "GET /", type: :request do
  context "with no published testimonials" do
    it "renders successfully" do
      get root_path

      expect(response).to have_http_status(:ok)
    end

    it "omits the testimonial section entirely" do
      get root_path

      expect(response.body).not_to include("Patient Stories")
    end

    it "omits it even when unpublished testimonials exist" do
      create(:testimonial, :unpublished, quote: "Hidden quote")

      get root_path

      expect(response.body).not_to include("Patient Stories")
      expect(response.body).not_to include("Hidden quote")
    end
  end

  context "with published testimonials" do
    it "renders the section" do
      create(:testimonial)

      get root_path

      expect(response.body).to include("Patient Stories")
    end

    it "renders the quote, author name, and role" do
      create(:testimonial,
        quote: "Matching took minutes instead of an afternoon.",
        author_name: "Dana Whitfield",
        author_role: "Research participant")

      get root_path

      expect(response.body).to include("Matching took minutes instead of an afternoon.")
      expect(response.body).to include("Dana Whitfield")
      expect(response.body).to include("Research participant")
    end

    it "renders initials when no avatar is attached" do
      create(:testimonial, author_name: "Dana Whitfield")

      get root_path

      expect(response.body).to include("DW")
    end

    it "renders a single-word author name without raising" do
      create(:testimonial, :single_word_name)

      expect { get root_path }.not_to raise_error
      expect(response).to have_http_status(:ok)
    end

    it "renders at most three" do
      5.times { |n| create(:testimonial, position: n, quote: "Quote number #{n}") }

      get root_path

      expect(response.body).to include("Quote number 0", "Quote number 1", "Quote number 2")
      expect(response.body).not_to include("Quote number 3")
      expect(response.body).not_to include("Quote number 4")
    end

    it "renders them in position order" do
      create(:testimonial, position: 2, quote: "Second in order")
      create(:testimonial, position: 1, quote: "First in order")

      get root_path

      expect(response.body.index("First in order")).to be < response.body.index("Second in order")
    end
  end
end

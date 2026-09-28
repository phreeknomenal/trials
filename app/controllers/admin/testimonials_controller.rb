module Admin
  class TestimonialsController < BaseController
    before_action :set_testimonial, only: [:edit, :update, :destroy]

    def index
      @testimonials = policy_scope(Testimonial).ordered
      @testimonial ||= Testimonial.new
      authorize Testimonial
    end

    # The board puts the new form beside the list rather than on a page of its
    # own, so a rejected create renders the list again with the form holding its
    # errors. There is no separate new page to fall back to.
    def create
      @testimonial = Testimonial.new(testimonial_params)
      authorize @testimonial

      if @testimonial.save
        redirect_to admin_testimonials_path, notice: "Testimonial created."
      else
        @testimonials = policy_scope(Testimonial).ordered
        render :index, status: :unprocessable_content
      end
    end

    def edit
      authorize @testimonial
    end

    def update
      authorize @testimonial

      if @testimonial.update(testimonial_params)
        redirect_to admin_testimonials_path, notice: "Testimonial updated."
      else
        render :edit, status: :unprocessable_content
      end
    end

    def destroy
      authorize @testimonial
      @testimonial.destroy

      # Placeholders are recreated by Seeds::Record::Testimonial, which runs on
      # every release via the Procfile. Say so rather than letting the record
      # reappear unexplained after the next deploy.
      notice = if @testimonial.placeholder?
        "Testimonial deleted. It is a seeded placeholder, so the next deploy will recreate it."
      else
        "Testimonial deleted."
      end

      redirect_to admin_testimonials_path, notice: notice
    end

    private

    def set_testimonial
      @testimonial = Testimonial.find(params[:id])
    end

    def testimonial_params
      params.require(:testimonial).permit(:quote, :author_name, :author_role, :position, :published, :avatar)
    end
  end
end

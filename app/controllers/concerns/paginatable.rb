module Paginatable
  extend ActiveSupport::Concern

  private

  def current_page
    @current_page ||= [params[:page].to_i, 1].max
  end

  def page_size
    @page_size ||= params[:per_page]&.to_i || default_page_size
  end

  def default_page_size
    10
  end
end

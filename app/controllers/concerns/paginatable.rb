module Paginatable
  extend ActiveSupport::Concern

  MIN_PAGE_SIZE = 1
  MAX_PAGE_SIZE = 100

  private

  def current_page
    @current_page ||= [params[:page].to_i, 1].max
  end

  # Clamped because these values reach Pagy, which raises Pagy::OptionError for
  # a limit below 1. Note that `params[:per_page]&.to_i || default` does not
  # work: "abc".to_i is 0, and 0 is truthy in Ruby, so the fallback never fires
  # and a non-numeric param silently became a limit of zero.
  def page_size
    @page_size ||= begin
      requested = params[:per_page].presence&.to_i

      if requested.nil? || requested < MIN_PAGE_SIZE
        default_page_size
      else
        [requested, MAX_PAGE_SIZE].min
      end
    end
  end

  def default_page_size
    10
  end
end

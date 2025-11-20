class SearchController < ApplicationController
  include Paginatable

  def index
    @conditions = Condition.order(:name)
    return unless search_params_present?

    initialize_page_tokens
    perform_search
  end

  def show
    @study = ClinicalTrialClient.get_study(params[:id])
    @error = @study[:error]
  end

  private

  def perform_search
    current_page_num = params[:page]&.to_i || 1
    page_token = get_page_token(current_page_num)

    result = ClinicalTrialClient.advanced_search(
      **sanitized_params,
      page_token: page_token,
      page_size: page_size
    )

    @studies = result[:studies]
    @total_count = result[:total_count]
    @error = result[:error]
    @current_page = current_page_num
    @has_next_page = result[:next_page_token].present?

    # Store the next page token for future use
    if result[:next_page_token].present?
      store_page_token(current_page_num + 1, result[:next_page_token])
    end
  end

  def sanitized_params
    @sanitized_params ||= {
      condition: params[:condition].presence,
      location: params[:location].presence
    }
  end

  def search_params_present?
    sanitized_params.values.any?(&:present?)
  end

  def pagination_params
    {
      condition: params[:condition].presence,
      location: params[:location].presence
    }.compact
  end
  helper_method :pagination_params

  def search_key
    # Create a unique key for this search to store tokens
    "#{sanitized_params[:condition]}_#{sanitized_params[:location]}"
  end

  def initialize_page_tokens
    # Reset token storage if this is a new search (page 1 without explicit navigation)
    if params[:page].blank? || params[:page].to_i == 1
      session[:page_tokens] ||= {}
      session[:page_tokens][search_key] = {}
    end
  end

  def get_page_token(page_num)
    return nil if page_num <= 1
    session.dig(:page_tokens, search_key, page_num)
  end

  def store_page_token(page_num, token)
    session[:page_tokens] ||= {}
    session[:page_tokens][search_key] ||= {}
    session[:page_tokens][search_key][page_num] = token
  end
end

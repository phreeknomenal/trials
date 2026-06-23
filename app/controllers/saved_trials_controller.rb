class SavedTrialsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_saved_trial, only: [:show, :edit, :update, :destroy]
  after_action :verify_authorized
  include Paginatable

  def index
    authorize SavedTrial
    @saved_trials = policy_scope(SavedTrial)
      .includes(:user)
      .order(created_at: :desc)

    # Filtering
    @saved_trials = @saved_trials.where(status: params[:status]) if params[:status].present?

    # Search in title and notes
    if params[:search].present?
      search_term = "%#{params[:search]}%"
      @saved_trials = @saved_trials.where(
        "trial_title ILIKE ? OR notes ILIKE ?",
        search_term,
        search_term
      )
    end

    # Sorting
    sort_order = (params[:sort] == "oldest") ? :asc : :desc
    @saved_trials = case params[:sort_by]
    when "status"
      @saved_trials.order(status: sort_order)
    when "match_score"
      @saved_trials.order(match_score: sort_order)
    else
      @saved_trials.order(created_at: sort_order)
    end

    # Pagination with Pagy
    @pagy, @saved_trials = pagy(@saved_trials, items: 20)
  end

  def show
    authorize @saved_trial
  end

  def edit
    authorize @saved_trial
  end

  def create
    @saved_trial = current_user.saved_trials.build(saved_trial_params)
    authorize @saved_trial

    if @saved_trial.save
      respond_to do |format|
        format.json { render json: @saved_trial, status: :created }
        format.turbo_stream
      end
    else
      respond_to do |format|
        format.json { render json: @saved_trial.errors, status: :unprocessable_entity }
        format.turbo_stream
      end
    end
  end

  def update
    authorize @saved_trial

    if @saved_trial.update(saved_trial_params)
      respond_to do |format|
        format.html { redirect_to saved_trial_path(@saved_trial), notice: "Trial updated successfully" }
      end
    else
      respond_to do |format|
        format.html { render :edit, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    authorize @saved_trial
    @saved_trial.destroy!

    respond_to do |format|
      format.turbo_stream
      format.json { head :no_content }
    end
  end

  private

  def set_saved_trial
    @saved_trial = SavedTrial.find(params[:id])
  end

  def saved_trial_params
    params.require(:saved_trial).permit(
      :nct_id, :trial_title, :notes, :tags, :status, :match_score,
      :phase, :study_type, :trial_status, :min_age, :max_age,
      :enrollment_count, :start_date, :completion_date, :sponsor, :summary
    )
  end
end

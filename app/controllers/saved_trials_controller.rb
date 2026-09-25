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

    # Search in title and notes. `notes` is an ActionText rich text, not a column
    # on saved_trials, so it has to be reached through a join on its body.
    # sanitize_sql_like escapes % and _ so searching "100%" matches the literal
    # string rather than acting as a wildcard.
    if params[:search].present?
      search_term = "%#{SavedTrial.sanitize_sql_like(params[:search])}%"
      @saved_trials = @saved_trials
        .left_joins(:rich_text_notes)
        .where(
          "saved_trials.trial_title ILIKE :term OR action_text_rich_texts.body ILIKE :term",
          term: search_term
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

    # Counted before pagination and before the status filter, so a rail entry
    # never removes its own option and strands whoever clicked it. Same rule the
    # search sidebar follows.
    @status_counts = policy_scope(SavedTrial).group(:status).count
    @total_count = @status_counts.values.sum

    # Pagination with Pagy
    # `limit:`, not `items:` -- Pagy 43 renamed it and ignores the old key,
    # so this paginated at Pagy's default rather than the value passed.
    @pagy, @saved_trials = pagy(@saved_trials, limit: page_size)
  end

  # One request for a whole selection.
  #
  # The page has offered a "Mark as" control for a multiple selection since it
  # was written, with no endpoint behind it, no JavaScript wiring it up, and a
  # container that starts hidden and is never unhidden. It has never done
  # anything at all.
  def bulk_update
    authorize SavedTrial

    status = params[:status].to_s
    ids = Array(params[:saved_trial_ids]).compact_blank

    unless SavedTrial::STATUSES.include?(status)
      return redirect_back fallback_location: saved_trials_path,
        alert: "#{status.presence || "That"} is not a status a study can be in."
    end

    # Scoped through the policy rather than found by id, so a forged id belonging
    # to somebody else updates nothing instead of raising.
    updated = policy_scope(SavedTrial).where(id: ids).update_all(status: status, updated_at: Time.current)

    redirect_back fallback_location: saved_trials_path,
      notice: "#{helpers.pluralize(updated, "study")} moved to #{status.humanize.downcase}."
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

    if @saved_trial.update(editable_params)
      respond_to do |format|
        format.html { redirect_to saved_trial_path(@saved_trial), notice: "Saved." }
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

  def default_page_size
    20
  end

  def set_saved_trial
    @saved_trial = SavedTrial.find(params[:id])
  end

  # Creating a saved trial snapshots the registry's own fields, so create needs
  # the wide list.
  def saved_trial_params
    params.require(:saved_trial).permit(
      :nct_id, :trial_title, :notes, :tags, :status, :match_score,
      :phase, :study_type, :trial_status, :min_age, :max_age,
      :enrollment_count, :start_date, :completion_date, :sponsor, :summary
    )
  end

  # Editing does not. The form offers notes, tags and status; it showed the match
  # score read-only and never offered the registry fields at all, but update
  # accepted all sixteen, so a hand-made POST could rewrite the snapshot or set
  # its own score. The dashboard counts saved trials at match_score >= 80, which
  # makes that the number worth forging.
  EDITABLE = %i[notes tags status].freeze

  def editable_params
    params.require(:saved_trial).permit(*EDITABLE)
  end
end

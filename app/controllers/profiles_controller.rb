class ProfilesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_profile, only: [:show, :edit, :update]

  def show
    authorize @profile
    @sections = ProfileSections.new(@profile)
    @strength = ProfileStrength.new(@profile)
    @editing = ProfileSections.find(params[:section]) if params[:section].present?
  end

  # A profile is created with the account, by User#add_default_profile, so this
  # is only reached when one has gone missing. It restores the record and hands
  # over to the wizard, which is where these answers are actually collected.
  # Rendering a second full-length form here only duplicated onboarding.
  def new
    return redirect_to profile_path(current_user.profile) if current_user.profile.present?

    # Authorized before building, because ProfilePolicy#new? asks that the user
    # has no profile and build_profile assigns one, so authorizing afterwards
    # denies the very case this action exists for.
    authorize Profile

    current_user.create_profile!

    redirect_to onboarding_path
  end

  # Editing happens on the profile page itself, one section at a time, so the
  # page never loses the context of what the rest of the answers are.
  def edit
    authorize @profile
    redirect_to profile_path(@profile, section: params[:section].presence || ProfileSections.all.first.slug)
  end

  # The turbo_stream branches here existed only to dismiss the onboarding modal
  # and re-render its form. The wizard owns onboarding now, so this is an
  # ordinary edit form again.
  def update
    authorize @profile

    if @profile.update(profile_params)
      redirect_to profile_path(@profile), notice: "#{editing_section&.heading || "Profile"} saved."
    else
      # Back to the same section with its errors, rather than to a page with no
      # indication of which of seven sections failed.
      @sections = ProfileSections.new(@profile)
      @strength = ProfileStrength.new(@profile)
      @editing = editing_section
      render :show, status: :unprocessable_entity
    end
  end

  private

  def set_profile
    @profile = Profile.find(params[:id])
  end

  def editing_section
    @editing_section ||= ProfileSections.find(params[:section]) if params[:section].present?
  end

  # Scoped to the section being edited when there is one. A form that shows five
  # fields should not be able to write twenty-five, and the section already
  # declares exactly which are its own.
  def profile_params
    return params.require(:profile).permit(*editing_section.permitted) if editing_section

    params.require(:profile).permit(
      :onboarded,
      :first_name,
      :last_name,
      :birth_year,
      :phone_number,
      :pronouns,
      :zip_code,
      :city,
      :state,
      :country,
      :sex_assigned_at_birth,
      :ethnicity,
      :gender_id,
      :race_id,
      :about,
      :avatar,
      :diagnosis_timing,
      :current_treatment,
      :prior_treatment,
      :willing_travel_miles,
      :transportation_reliable,
      :remote_visit_preference,
      :trial_type_preference,
      :risk_tolerance,
      :contact_preference,
      :language_preference,
      identity_ids: [],
      interest_ids: [],
      condition_ids: [],
      profile_conditions_attributes: [:id, :condition_id, :is_primary, :_destroy]
    )
  end
end

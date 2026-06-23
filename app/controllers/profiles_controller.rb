class ProfilesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_profile, only: [:show, :edit, :update]

  def show
    authorize @profile
  end

  def new
    if current_user.profile.present?
      redirect_to edit_profile_path(current_user.profile), notice: "You already have a profile. You can edit it here."
      return
    end

    @profile = Profile.new
    authorize @profile
  end

  def create
    @profile = current_user.build_profile(profile_params)
    authorize @profile

    if @profile.save
      redirect_to profile_path(@profile), notice: "Profile was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @profile
  end

  def update
    authorize @profile

    respond_to do |format|
      if @profile.update(profile_params)
        format.turbo_stream do
          flash.now[:notice] = "Your profile was successfully completed!"
          render turbo_stream: [
            turbo_stream.replace("main-flash-messages", partial: "shared/utilities/flash_messages"),
            turbo_stream.remove("profile-onboarding-modal")
          ]
        end
        format.html { redirect_to profile_path(@profile), notice: "Profile was successfully updated." }
      else
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "profile-onboarding-form",
            Profiles::OnboardingFormComponent.new(profile: @profile)
          ), status: :unprocessable_entity
        end
        format.html { render :edit, status: :unprocessable_entity }
      end
    end
  end

  private

  def set_profile
    @profile = Profile.find(params[:id])
  end

  def profile_params
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

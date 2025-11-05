class ProfilesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_profile, only: [ :show, :edit, :update ]

  def show
  end

  def edit
  end

  def update
    if @profile.update(profile_params)
      redirect_to profile_path(@profile), notice: "Profile was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_profile
    @profile = Profile.find(params[:id])
  end

  def profile_params
    params.require(:profile).permit(
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
      :primary_condition,
      :condition_subtype,
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
      interest_ids: []
    )
  end
end

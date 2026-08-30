require "faker"

class Seeds::Record::User
  class << self
    def seed
      ActiveRecord::Base.transaction do
        user_params.each do |params|
          profile_attrs = params.delete(:profile_attributes)

          user = User.find_or_initialize_by(email: params[:email])
          next if user.persisted? # Skip if user already exists

          user.assign_attributes(params)
          user.build_profile(profile_attrs)
          user.save(validate: false)

          create_profile_associations(user.profile)
        end
      end
    end

    private

    def user_params
      admin_user_params + member_user_params
    end

    def admin_user_params
      [
        {email: "marques@example.com", password: admin_password, role: "super_admin", profile_attributes: profile_params},
        {email: "bryan@example.com", password: admin_password, role: "super_admin", profile_attributes: profile_params},
        {email: "austin@example.com", password: admin_password, role: "super_admin", profile_attributes: profile_params},
        {email: "jaeson@example.com", password: admin_password, role: "super_admin", profile_attributes: profile_params}
      ]
    end

    def admin_password
      Rails.env.development? ? "password" : SecureRandom.hex(12)
    end

    # Deterministic emails, not Faker. The seed skips users that already exist by
    # email, so random addresses meant every run created 25 more members --
    # development reached 79 users from repeated seeding, which distorts every
    # count on the admin dashboard. Profile attributes stay randomised; only the
    # identity key needs to be stable.
    def member_user_params
      25.times.map do |index|
        {
          email: "member#{index + 1}@trials.test",
          password: SecureRandom.hex(12),
          role: User::COMMUNITY_ROLES.sample,
          profile_attributes: profile_params
        }
      end
    end

    def profile_params
      {
        first_name: Faker::Name.first_name,
        last_name: Faker::Name.last_name,
        birth_year: Faker::Date.between(from: 80.years.ago, to: 18.years.ago).year,
        gender: genders.sample,
        race: races.sample,
        pronouns: Profile::PRONOUN_OPTIONS.sample,
        sex_assigned_at_birth: Profile::SEX_ASSIGNED_AT_BIRTH_OPTIONS.sample,
        ethnicity: Profile::ETHNICITY_OPTIONS.sample,
        city: Faker::Address.city,
        state: Faker::Address.state,
        country: "US",
        zip_code: Faker::Address.zip_code,
        phone_number: Faker::PhoneNumber.cell_phone,
        diagnosis_timing: Profile::DIAGNOSIS_TIMING_OPTIONS.sample,
        current_treatment: Profile::TREATMENT_OPTIONS.sample,
        prior_treatment: [true, false].sample,
        willing_travel_miles: Profile::TRAVEL_MILES_OPTIONS.sample,
        transportation_reliable: [true, false].sample,
        remote_visit_preference: Profile::REMOTE_VISIT_PREFERENCE_OPTIONS.sample,
        trial_type_preference: Profile::TRIAL_TYPE_PREFERENCE_OPTIONS.sample,
        risk_tolerance: Profile::RISK_TOLERANCE_OPTIONS.sample,
        contact_preference: Profile::CONTACT_PREFERENCE_OPTIONS.sample,
        language_preference: Faker::Nation.language,
        about: Faker::Lorem.paragraph(sentence_count: 5)
      }
    end

    def genders
      @genders ||= Gender.all
    end

    def races
      @races ||= Race.all
    end

    def conditions
      @conditions ||= Condition.all
    end

    def create_profile_associations(profile)
      profile_identities = identities.sample(rand(1..5)).map do |identity|
        ProfileIdentity.new(profile: profile, identity: identity)
      end
      ProfileIdentity.import(profile_identities)

      profile_interests = interests.sample(rand(1..5)).map do |interest|
        ProfileInterest.new(profile: profile, interest: interest)
      end
      ProfileInterest.import(profile_interests)

      profile_conditions = conditions.sample(rand(1..5)).map do |condition|
        ProfileCondition.new(profile: profile, condition: condition)
      end
      ProfileCondition.import(profile_conditions)
    end

    def identities
      @identities ||= Identity.all
    end

    def interests
      @interests ||= Interest.all
    end
  end
end

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
        end
      end
    end

    private

    def user_params
      admin_user_params + member_user_params
    end

    def admin_user_params
      [
        { email: "marques@acclinate.com", password: admin_password, role: "super_admin", profile_attributes: profile_params },
        { email: "bryan@acclinate.com", password: admin_password, role: "super_admin", profile_attributes: profile_params },
        { email: "austin@acclinate.com", password: admin_password, role: "super_admin", profile_attributes: profile_params },
        { email: "jaeson@acclinate.com", password: admin_password, role: "super_admin", profile_attributes: profile_params }
      ]
    end

    def admin_password
      Rails.env.development? ? "password" : SecureRandom.hex(12)
    end

    def member_user_params
      25.times.map do
        {
          email: Faker::Internet.email,
          password: SecureRandom.hex(12),
          role: User::COMMUNITY_ROLES.sample,
          profile_attributes: profile_params
        }
      end
    end

    def profile_params
      {
        gender: genders.sample,
        first_name: Faker::Name.first_name,
        last_name: Faker::Name.last_name,
        birth_date: Faker::Date.between(from: 80.years.ago, to: 18.years.ago),
        zip_code: Faker::Address.zip_code,
        phone_number: Faker::PhoneNumber.cell_phone
      }
    end

    def genders
      @genders ||= Gender.all
    end
  end
end

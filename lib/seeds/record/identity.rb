class Seeds::Record::Identity
  class << self
    def seed
      ActiveRecord::Base.transaction do
        existing_names = Identity.pluck(:name)
        new_identities = identity_params.reject { |params| existing_names.include?(params[:name]) }

        unless new_identities.empty?
          identities = new_identities.map { |params| Identity.new(name: params[:name]) }
          Identity.import(identities)
        end
      end
    end

    private

    def identity_params
      [
        { name: "patient" },
        { name: "caregiver" },
        { name: "physician" },
        { name: "nurse" },
        { name: "clinical researcher" },
        { name: "clinical trial participant" },
        { name: "community health worker" },
        { name: "patient advocate" },
        { name: "public health professional" },
        { name: "student / trainee" },
        { name: "medical student" },
        { name: "nurse practitioner" },
        { name: "physician assistant" },
        { name: "therapist" },
        { name: "psychologist / psychiatrist" },
        { name: "research coordinator" },
        { name: "principal investigator" },
        { name: "academic researcher" },
        { name: "faith-based leader" },
        { name: "health educator" },
        { name: "community member" },
        { name: "health advocate" },
        { name: "survivor" },
        { name: "long-term patient" },
        { name: "policy maker" },
        { name: "health tech professional" },
        { name: "nonprofit worker" },
        { name: "volunteer" },
        { name: "sponsor / CRO representative" },
        { name: "health influencer" },
        { name: "support group leader" }
      ]
    end
  end
end

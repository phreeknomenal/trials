class Seeds::Record::Condition
  class << self
    def seed
      ActiveRecord::Base.transaction do
        existing_names = Condition.pluck(:name)
        new_conditions = condition_params.reject { |params| existing_names.include?(params[:name]) }

        unless new_conditions.empty?
          conditions = new_conditions.map { |params| Condition.new(name: params[:name]) }
          Condition.import(conditions)
        end
      end
    end

    private

    def condition_params
      [
        # Cancer conditions
        {name: "breast cancer"},
        {name: "lung cancer"},
        {name: "prostate cancer"},
        {name: "colorectal cancer"},
        {name: "melanoma"},
        {name: "leukemia"},
        {name: "lymphoma"},
        {name: "pancreatic cancer"},
        {name: "ovarian cancer"},
        {name: "brain cancer"},

        # Cardiovascular conditions
        {name: "heart disease"},
        {name: "coronary artery disease"},
        {name: "heart failure"},
        {name: "atrial fibrillation"},
        {name: "hypertension"},
        {name: "stroke"},
        {name: "peripheral artery disease"},

        # Metabolic conditions
        {name: "type 1 diabetes"},
        {name: "type 2 diabetes"},
        {name: "obesity"},
        {name: "metabolic syndrome"},
        {name: "thyroid disease"},
        {name: "hyperlipidemia"},

        # Neurological conditions
        {name: "alzheimer's disease"},
        {name: "parkinson's disease"},
        {name: "multiple sclerosis"},
        {name: "epilepsy"},
        {name: "migraine"},
        {name: "neuropathy"},
        {name: "amyotrophic lateral sclerosis (ALS)"},

        # Respiratory conditions
        {name: "asthma"},
        {name: "chronic obstructive pulmonary disease (COPD)"},
        {name: "pulmonary fibrosis"},
        {name: "cystic fibrosis"},
        {name: "sleep apnea"},

        # Autoimmune conditions
        {name: "rheumatoid arthritis"},
        {name: "lupus"},
        {name: "psoriasis"},
        {name: "inflammatory bowel disease"},
        {name: "crohn's disease"},
        {name: "ulcerative colitis"},
        {name: "celiac disease"},

        # Mental health conditions
        {name: "depression"},
        {name: "anxiety disorder"},
        {name: "bipolar disorder"},
        {name: "schizophrenia"},
        {name: "post-traumatic stress disorder (PTSD)"},
        {name: "obsessive-compulsive disorder (OCD)"},

        # Infectious diseases
        {name: "HIV/AIDS"},
        {name: "hepatitis B"},
        {name: "hepatitis C"},
        {name: "tuberculosis"},

        # Kidney and urological
        {name: "chronic kidney disease"},
        {name: "kidney failure"},
        {name: "urinary incontinence"},

        # Musculoskeletal
        {name: "osteoarthritis"},
        {name: "osteoporosis"},
        {name: "fibromyalgia"},
        {name: "chronic pain"},

        # Eye conditions
        {name: "macular degeneration"},
        {name: "glaucoma"},
        {name: "diabetic retinopathy"},

        # Skin conditions
        {name: "eczema"},
        {name: "acne"},

        # Blood disorders
        {name: "sickle cell disease"},
        {name: "anemia"},
        {name: "hemophilia"},

        # Other common conditions
        {name: "chronic fatigue syndrome"},
        {name: "irritable bowel syndrome (IBS)"},
        {name: "endometriosis"},
        {name: "polycystic ovary syndrome (PCOS)"},
        {name: "gastroesophageal reflux disease (GERD)"}
      ]
    end
  end
end

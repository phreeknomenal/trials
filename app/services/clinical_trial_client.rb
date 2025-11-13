class ClinicalTrialClient
  include HTTParty
  base_uri "https://clinicaltrials.gov/api/v2"

  TRIAL_STATUSES = [
    "Recruiting",
    "Active, not recruiting",
    "Completed",
    "Enrolling by invitation",
    "Not yet recruiting",
    "Suspended",
    "Terminated",
    "Withdrawn"
  ].freeze

  def self.search(query, page: 1, page_size: 10)
    return { studies: [], total_count: 0 } if query.blank?

    response = get("/studies", query: {
      "query.term" => query,
      "pageSize" => page_size,
      "pageToken" => page > 1 ? page.to_s : nil,
      "format" => "json"
    }.compact)

    if response.success?
      parse_response(response)
    else
      { studies: [], total_count: 0, error: "API request failed" }
    end
  rescue StandardError => e
    { studies: [], total_count: 0, error: e.message }
  end

  def self.advanced_search(condition: nil, location: nil, page: 1, page_size: 10)
    query_parts = []

    # Build simple query parts
    query_parts << condition if condition.present?
    query_parts << location if location.present?

    return { studies: [], total_count: 0 } if query_parts.empty?

    # Build query parameters
    query_params = {
      "query.term" => query_parts.join(" "),
      "pageSize" => page_size,
      "pageToken" => page > 1 ? page.to_s : nil,
      "format" => "json"
    }.compact

    Rails.logger.info("ClinicalTrials API Request: /studies with params: #{query_params.inspect}")
    response = get("/studies", query: query_params)

    if response.success?
      parse_response(response)
    else
      Rails.logger.error("ClinicalTrials API Error: #{response.code} - #{response.message}")
      Rails.logger.error("Response body: #{response.body}")
      { studies: [], total_count: 0, error: "Unable to fetch trials (Status: #{response.code}). Please try different search terms." }
    end
  rescue StandardError => e
    Rails.logger.error("ClinicalTrials API Exception: #{e.class} - #{e.message}")
    Rails.logger.error(e.backtrace.join("\n"))
    { studies: [], total_count: 0, error: "Search temporarily unavailable. Please try again later." }
  end

  def self.get_study(nct_id)
    return { error: "NCT ID is required" } if nct_id.blank?

    Rails.logger.info("ClinicalTrials API Request: /studies/#{nct_id}")
    response = get("/studies/#{nct_id}", query: {
      "format" => "json"
    })

    Rails.logger.info("API Response Code: #{response.code}")

    if response.success?
      data = response.parsed_response
      Rails.logger.info("API Response Data: #{data.inspect[0..500]}")

      # Single study endpoint returns data directly, not wrapped in "studies" array
      if data["protocolSection"]
        format_study(data)
      elsif data["studies"]&.first
        format_study(data["studies"].first)
      else
        Rails.logger.error("No study data found in response for #{nct_id}")
        { error: "Study not found" }
      end
    else
      Rails.logger.error("API request failed for #{nct_id}: #{response.code} - #{response.message}")
      Rails.logger.error("Response body: #{response.body}")
      { error: "Unable to load trial details. Please try again." }
    end
  rescue StandardError => e
    Rails.logger.error("Exception getting study #{nct_id}: #{e.class} - #{e.message}")
    Rails.logger.error(e.backtrace.join("\n"))
    { error: "Error loading trial details: #{e.message}" }
  end

  def self.parse_response(response)
    data = response.parsed_response
    studies = data.dig("studies") || []
    formatted_studies = studies.map { |study| format_study(study) }

    {
      studies: formatted_studies,
      total_count: formatted_studies.length, # API v2 doesn't provide totalCount, use page count
      next_page_token: data.dig("nextPageToken")
    }
  end

  def self.format_study(study)
    protocol = study.dig("protocolSection") || {}
    identification = protocol.dig("identificationModule") || {}
    status = protocol.dig("statusModule") || {}
    description = protocol.dig("descriptionModule") || {}
    conditions = protocol.dig("conditionsModule") || {}
    contacts = protocol.dig("contactsLocationsModule") || {}
    sponsors = protocol.dig("sponsorCollaboratorsModule") || {}
    eligibility = protocol.dig("eligibilityModule") || {}
    design = protocol.dig("designModule") || {}
    arms_interventions = protocol.dig("armsInterventionsModule") || {}
    outcomes = protocol.dig("outcomesModule") || {}

    {
      nct_id: identification.dig("nctId"),
      title: identification.dig("briefTitle") || identification.dig("officialTitle"),
      status: status.dig("overallStatus"),
      summary: description.dig("briefSummary"),
      detailed_description: description.dig("detailedDescription"),
      conditions: conditions.dig("conditions") || [],
      phase: design.dig("phases")&.join(", "),
      start_date: status.dig("startDateStruct", "date"),
      completion_date: status.dig("completionDateStruct", "date") || status.dig("primaryCompletionDateStruct", "date"),
      sponsor: sponsors.dig("leadSponsor", "name"),
      min_age: eligibility.dig("minimumAge"),
      max_age: eligibility.dig("maximumAge"),
      sex: eligibility.dig("sex"),
      inclusion_criteria: eligibility.dig("eligibilityCriteria"),
      enrollment_count: design.dig("enrollmentInfo", "count"),
      enrollment_type: design.dig("enrollmentInfo", "type"),
      interventions: extract_interventions(arms_interventions),
      locations: extract_locations(contacts),
      # Study Type & Design
      study_type: design.dig("studyType"),
      design_allocation: design.dig("designInfo", "allocation"),
      design_intervention_model: design.dig("designInfo", "interventionModel"),
      design_masking: design.dig("designInfo", "maskingInfo", "masking"),
      design_primary_purpose: design.dig("designInfo", "primaryPurpose"),
      # Outcome Measures
      primary_outcomes: extract_outcomes(outcomes.dig("primaryOutcomes")),
      secondary_outcomes: extract_outcomes(outcomes.dig("secondaryOutcomes")),
      # Contact Information
      central_contacts: extract_contacts(contacts.dig("centralContacts")),
      overall_officials: extract_officials(contacts.dig("overallOfficials")),
      # Why Stopped
      why_stopped: status.dig("whyStopped")
    }
  end

  def self.extract_locations(contacts)
    locations = contacts.dig("locations") || []
    locations.first(3).map do |loc|
      [ loc["city"], loc["state"], loc["country"] ].compact.join(", ")
    end
  end

  def self.extract_interventions(arms_interventions)
    interventions = arms_interventions.dig("interventions") || []
    interventions.map do |intervention|
      {
        type: intervention["type"],
        name: intervention["name"],
        description: intervention["description"]
      }
    end
  end

  def self.extract_outcomes(outcomes)
    return [] unless outcomes

    outcomes.map do |outcome|
      {
        measure: outcome["measure"],
        description: outcome["description"],
        time_frame: outcome["timeFrame"]
      }
    end
  end

  def self.extract_contacts(contacts)
    return [] unless contacts

    contacts.map do |contact|
      {
        name: contact["name"],
        role: contact["role"],
        phone: contact["phone"],
        email: contact["email"]
      }
    end
  end

  def self.extract_officials(officials)
    return [] unless officials

    officials.map do |official|
      {
        name: official["name"],
        role: official["role"],
        affiliation: official["affiliation"]
      }
    end
  end
end

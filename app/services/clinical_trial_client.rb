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

  def self.advanced_search(condition: nil, location: nil, status: nil, min_age: nil, max_age: nil, page: 1, page_size: 10)
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

    # Add status filter if provided
    query_params["filter.overallStatus"] = status if status.present?

    Rails.logger.info("ClinicalTrials API Request: /studies with params: #{query_params.inspect}")
    response = get("/studies", query: query_params)

    if response.success?
      result = parse_response(response)

      # Client-side age filtering if needed
      if (min_age.present? || max_age.present?) && result[:studies].present?
        result[:studies] = filter_by_age(result[:studies], min_age, max_age)
        result[:total_count] = result[:studies].length
      end

      result
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

    {
      studies: studies.map { |study| format_study(study) },
      total_count: data.dig("totalCount") || 0,
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

    {
      nct_id: identification.dig("nctId"),
      title: identification.dig("briefTitle") || identification.dig("officialTitle"),
      status: status.dig("overallStatus"),
      summary: description.dig("briefSummary"),
      conditions: conditions.dig("conditions") || [],
      phase: protocol.dig("designModule", "phases")&.join(", "),
      start_date: status.dig("startDateStruct", "date"),
      locations: extract_locations(contacts)
    }
  end

  def self.extract_locations(contacts)
    locations = contacts.dig("locations") || []
    locations.first(3).map do |loc|
      [ loc["city"], loc["state"], loc["country"] ].compact.join(", ")
    end
  end

  def self.filter_by_age(studies, min_age, max_age)
    # Note: This is client-side filtering since the API doesn't support age filtering well
    # In production, you might want to extract age eligibility from the study details
    # For now, we'll return all studies as the API doesn't provide structured age data
    studies
  end
end

class ClinicalTrialClient
  include HTTParty
  base_uri "https://clinicaltrials.gov/api/v2"

  def self.search(query, page: 1, page_size: 10)
    return {studies: [], total_count: 0} if query.blank?

    response = get("/studies", query: {
      "query.term" => query,
      "pageSize" => page_size,
      "pageToken" => page > 1 ? page.to_s : nil,
      "format" => "json"
    }.compact)

    if response.success?
      parse_response(response)
    else
      {studies: [], total_count: 0, error: "API request failed"}
    end
  rescue StandardError => e
    {studies: [], total_count: 0, error: e.message}
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
      [loc["city"], loc["state"], loc["country"]].compact.join(", ")
    end
  end
end

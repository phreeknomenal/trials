class ReadableStudySummaryGenerator
  class GenerationError < StandardError; end

  MODEL = "claude-opus-4-8".freeze
  MAX_TOKENS = 1024

  SYSTEM_PROMPT = <<~PROMPT.freeze
    You rewrite dense clinical trial descriptions into plain, patient-facing language.
    Rewrite the provided text so a general audience with no medical background can understand it.
    Avoid jargon and technical terms; when a medical term is unavoidable, briefly explain it in everyday words.
    Preserve factual accuracy and do not add information that is not in the source.
    Do not give medical advice or recommendations.
    Output plain prose only. Do not use Markdown, headings, bullet points, or any formatting.
  PROMPT

  def initialize(nct_id)
    @nct_id = nct_id
  end

  def call
    study = ClinicalTrialClient.get_study(@nct_id)
    raise GenerationError, study[:error] if study[:error].present?

    source = [study[:summary], study[:detailed_description]].compact.join("\n\n")
    raise GenerationError, "No source text available to summarize" if source.blank?

    request_summary(source)
  end

  private

  def request_summary(source)
    message = client.messages.create(
      model: MODEL,
      max_tokens: MAX_TOKENS,
      output_config: {effort: :low},
      system_: SYSTEM_PROMPT,
      messages: [{role: "user", content: source}]
    )

    raise GenerationError, "The model refused to generate a summary" if message.stop_reason.to_s == "refusal"

    text = extract_text(message)
    raise GenerationError, "The model returned an empty summary" if text.blank?

    text
  end

  def extract_text(message)
    message.content
      .select { |block| block.type.to_s == "text" }
      .map(&:text)
      .join("\n\n")
      .strip
  end

  def client
    @client ||= Anthropic::Client.new(api_key: api_key)
  end

  def api_key
    Rails.application.credentials.dig(:anthropic, :api_key)
  end
end

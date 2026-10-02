# Rewrites a study's eligibility criteria as yes or no questions a patient can
# answer about themselves.
#
# Structured output, not prose, so the questions arrive as data with a fixed
# shape. The answer that keeps someone eligible is part of that shape, set by
# the model per question, because an exclusion asked as "Do you smoke?"
# qualifies on "no" and nothing in the wording says so reliably.
#
# Every question quotes the criterion it came from, and a question whose quote
# is not in the study's text is dropped. The page shows that quote as the
# study's own words, so a paraphrase citing a sentence the study never wrote is
# the one failure this cannot let through.
class StudyPrescreenGenerator
  class GenerationError < StandardError; end

  MODEL = "claude-opus-5-5".freeze

  # Non-streaming, so well under the SDK's HTTP timeout. A dozen short
  # questions is a fraction of this.
  MAX_TOKENS = 16_000

  # Routes a refused request to a substitute model by refusal category, rather
  # than leaving the study with no questions.
  BETAS = [:"server-side-fallback-2026-07-01"].freeze

  SYSTEM_PROMPT = <<~PROMPT.freeze
    You turn a clinical trial's eligibility criteria into short yes or no questions that a patient can answer about themselves, in plain language with no medical training assumed.

    Only ask about what a person would know about their own life and health: diagnoses they have been given, treatments and medicines they have had, pregnancy, smoking, and similar. Skip criteria that need a test result, a clinician's assessment, or the study team's judgment, such as lab values, performance scores, organ function, or "in the opinion of the investigator". The study team checks those at screening, so asking a patient produces only "not sure".

    Keep the criterion's meaning exactly, including time windows and thresholds. Do not add conditions, explain the study, or advise whether to join.

    For each question:
    - source: the criterion it comes from, copied word for word from the text you were given.
    - side: "inclusion" or "exclusion", whichever list the criterion is in.
    - qualifying_answer: the answer that keeps the person eligible for that criterion. For an exclusion criterion this is usually "no".

    Ask about the criteria most likely to decide eligibility first. Return at most #{StudyPrescreen::MAX_QUESTIONS} questions, and none if no criterion can be answered by a patient.
  PROMPT

  SCHEMA = {
    type: "object",
    additionalProperties: false,
    required: ["questions"],
    properties: {
      questions: {
        type: "array",
        items: {
          type: "object",
          additionalProperties: false,
          required: %w[text source side qualifying_answer],
          properties: {
            text: {type: "string"},
            source: {type: "string"},
            side: {type: "string", enum: StudyPrescreen::SIDES},
            qualifying_answer: {type: "string", enum: PrescreenAnswer::DECIDED}
          }
        }
      }
    }
  }.freeze

  Result = Data.define(:questions, :criteria_digest)

  def initialize(nct_id)
    @nct_id = nct_id
  end

  def call
    study = ClinicalTrialClient.get_study(@nct_id)
    raise GenerationError, study[:error] if study[:error].present?
    raise GenerationError, "This study lists no eligibility criteria" unless StudyPrescreen.criteria?(study)

    digest = StudyPrescreen.digest_for(study)
    raw = request_questions(prompt_for(study))

    Result.new(questions: keep_grounded(raw, study, digest), criteria_digest: digest)
  end

  private

  def prompt_for(study)
    [
      "Inclusion criteria:\n#{study[:inclusion_criteria].presence || "(none listed)"}",
      "Exclusion criteria:\n#{study[:exclusion_criteria].presence || "(none listed)"}"
    ].join("\n\n")
  end

  def request_questions(prompt)
    message = client.beta.messages.create(
      model: MODEL,
      max_tokens: MAX_TOKENS,
      betas: BETAS,
      fallbacks: :default,
      output_config: {effort: :medium, format_: {type: :json_schema, schema: SCHEMA}},
      system_: SYSTEM_PROMPT,
      messages: [{role: "user", content: prompt}]
    )

    raise GenerationError, "The model declined to write questions for this study" if message.stop_reason.to_s == "refusal"
    raise GenerationError, "The questions ran longer than we allow" if message.stop_reason.to_s == "max_tokens"

    text = message.content.select { |block| block.type.to_s == "text" }.map(&:text).join
    JSON.parse(text).fetch("questions")
  rescue JSON::ParserError, KeyError => e
    raise GenerationError, "The model returned questions we could not read (#{e.class})"
  end

  # Keys are the digest plus position, so rewritten questions never collide
  # with answers given to an earlier version.
  def keep_grounded(raw, study, digest)
    sides = {
      "inclusion" => normalize(study[:inclusion_criteria]),
      "exclusion" => normalize(study[:exclusion_criteria])
    }

    raw
      .select { |question| sides.fetch(question["side"], "").include?(normalize(question["source"])) }
      .reject { |question| normalize(question["source"]).blank? }
      .first(StudyPrescreen::MAX_QUESTIONS)
      .each_with_index
      .map { |question, index| question.slice(*%w[text source side qualifying_answer]).merge("key" => "#{digest.first(10)}-#{index}") }
  end

  # Whitespace and case only. Bullet characters survive in both strings, so a
  # quote taken from a bulleted line still matches.
  def normalize(text)
    text.to_s.squish.downcase
  end

  def client
    @client ||= Anthropic::Client.new(api_key: ENV.fetch("ANTHROPIC_API_KEY"))
  end
end

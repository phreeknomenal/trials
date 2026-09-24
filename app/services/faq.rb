# The FAQ, as data rather than as markup.
#
# One list, so the page, the category rail and the client-side filter cannot
# disagree about what questions exist, and so a spec can check every answer
# against what the app actually does.
#
# That check mattered. Six of the twelve answers on the design board described
# features the app does not have: a placebo flag on every listing, a visit
# schedule, what insurance covers, a filter for travel reimbursement, and an
# automatic record of which study teams replied. They read as fact because they
# are prose rather than numbers, which is what makes them worse than an invented
# figure, not better. Each has been rewritten to say what the study page really
# shows. See Answer#claims for the ones that still name an app feature.
class Faq
  Entry = Data.define(:category, :question, :answer, :unanswered) do
    # An entry with no answer yet. It renders as a marked gap rather than as a
    # confident sentence somebody wrote to fill the space.
    def unanswered? = unanswered

    def anchor = question.parameterize
  end

  # Order is the order on the page and in the rail.
  CATEGORIES = [
    "Taking part in a study",
    "Cost and insurance",
    "Your data and privacy",
    "Using Dira Health"
  ].freeze

  ENTRIES = [
    Entry.new(
      category: "Taking part in a study",
      question: "What actually happens in a clinical trial?",
      answer: "A study team checks whether you are eligible, explains what the study involves, and asks you to sign a consent form. After that you follow the study's visit schedule. You can leave at any point, for any reason, and leaving does not affect your regular care.",
      unanswered: false
    ),
    Entry.new(
      category: "Taking part in a study",
      question: "Could I be given a placebo?",
      # The board said "every listing says whether there is a placebo group".
      # The registry does not return that as a field. What it does return, and
      # what the study page shows, is the masking and the interventions.
      answer: "It depends on the study design. The registry does not publish a plain yes or no, so the study page shows you the next best thing: who knows which group a participant is in, and every intervention the study is comparing. If a placebo is one of them, it is named there.",
      unanswered: false
    ),
    Entry.new(
      category: "Taking part in a study",
      question: "How long does a study take?",
      # The board promised a visit schedule. There is none in the registry
      # response, which PR 5 established; time frames on the primary outcomes
      # are what exists.
      answer: "From a single visit to several years, and the registry does not publish a visit-by-visit schedule. The study page shows the start and completion dates and the time frame on each primary outcome, in the study's own words. The study team can tell you what the visits actually look like.",
      unanswered: false
    ),
    Entry.new(
      category: "Taking part in a study",
      question: "Should I tell my own doctor?",
      answer: "Yes. We are not a medical provider and a match score is not advice. Your own doctor knows things about your history that a profile here does not.",
      unanswered: false
    ),

    Entry.new(
      category: "Cost and insurance",
      question: "Do I need insurance?",
      # The board said "each listing says what that study covers". It does not.
      answer: "Most studies cover the treatment being tested. Coverage for the routine care around it varies by study and by your plan, and the registry does not publish it, so we cannot show it on a listing. Ask the study team before you agree to anything, and ask your insurer separately.",
      unanswered: false
    ),
    Entry.new(
      category: "Cost and insurance",
      question: "Will travel be paid for?",
      # The board promised a filter for it. There is no such field and no such
      # filter; the sidebar filters phase and study type only.
      answer: "Some studies reimburse travel and lodging, and some pay for your time. The registry does not publish either, so we cannot show it on a listing or filter for it. It is a good first question for the study coordinator.",
      unanswered: false
    ),
    Entry.new(
      category: "Cost and insurance",
      question: "Does Dira Health cost anything?",
      answer: nil,
      unanswered: true
    ),

    Entry.new(
      category: "Your data and privacy",
      question: "Who sees what I enter?",
      answer: "Nobody outside Dira Health, until you open a study and choose to send your details to that team. The privacy policy lists every field we hold and why.",
      unanswered: false
    ),
    Entry.new(
      category: "Your data and privacy",
      question: "Do I have to create an account to search?",
      answer: "No. Search works signed out, and shows each study's own stated eligibility. An account adds a match score against your profile, saved studies, notes and tags.",
      unanswered: false
    ),
    Entry.new(
      category: "Your data and privacy",
      question: "Can I delete everything?",
      # It is on account settings, not the profile page.
      answer: "Yes. Account settings has a delete button that removes your account, your health profile, your saved studies and your notes. Studies you already contacted keep whatever you sent them, and you would need to ask those teams directly.",
      unanswered: false
    ),

    Entry.new(
      category: "Using Dira Health",
      question: "Where do the studies come from?",
      answer: "ClinicalTrials.gov, the public registry. We do not choose what appears and a study cannot pay to rank higher. Listings drop off when enrollment closes.",
      unanswered: false
    ),
    Entry.new(
      category: "Using Dira Health",
      question: "What does the match score mean?",
      answer: "How well what you told us lines up with what a study says it needs, from 0 to 100. Every score opens to show the criteria behind it, including the ones you do not meet. Only the study team can confirm whether you are eligible.",
      unanswered: false
    ),
    Entry.new(
      category: "Using Dira Health",
      question: "How soon will a study team reply?",
      # The board said "most respond within a week", which is an invented
      # number, and "your saved studies track who has answered", which the app
      # does not do: the status on a saved study is one you set yourself.
      answer: "Replies come from the study team, not from us, and we have no way to know how long a given team takes. You can set a status on each saved study yourself, so the ones you are waiting on stay visible.",
      unanswered: false
    )
  ].freeze

  class << self
    def entries = ENTRIES

    def for_category(category) = ENTRIES.select { |e| e.category == category }

    def unanswered = ENTRIES.select(&:unanswered?)

    def categories = CATEGORIES
  end
end

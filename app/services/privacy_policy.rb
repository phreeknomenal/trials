# The privacy policy's sections, as one list.
#
# The table of contents and the body both read it, which is the fix for what the
# design board drew: a contents rail with eight entries above a page that had
# four sections. Six of the eight links would have gone nowhere, and the link
# would have looked fine and done nothing, which is precisely the failure PR 5
# found on the study detail page.
#
# A section with `partial: nil` has not been written. It still renders, still
# has its id, and still says what it is waiting on, so the contents rail is
# never a promise the page does not keep.
class PrivacyPolicy
  Section = Data.define(:slug, :title, :partial, :waiting_on) do
    def written? = partial.present?

    def anchor = "##{slug}"
  end

  SECTIONS = [
    Section.new(
      slug: "what-we-collect",
      title: "What we collect",
      partial: "pages/privacy/what_we_collect",
      waiting_on: nil
    ),
    Section.new(
      slug: "why-we-collect-it",
      title: "Why we collect it",
      partial: nil,
      waiting_on: "A reason per item in the table above. Most of them are one line, " \
                  "and the ones that are not are the interesting ones."
    ),
    Section.new(
      slug: "who-else-sees-it",
      title: "Who else sees it",
      partial: "pages/privacy/who_else_sees_it",
      waiting_on: nil
    ),
    Section.new(
      slug: "how-long-we-keep-it",
      title: "How long we keep it",
      partial: nil,
      waiting_on: "Retention periods, per category. Right now the honest answer is " \
                  "\"until you delete your account\", and that should be written down " \
                  "deliberately rather than by default."
    ),
    Section.new(
      slug: "your-choices",
      title: "Your choices",
      partial: "pages/privacy/your_choices",
      waiting_on: nil
    ),
    Section.new(
      slug: "cookies-and-sessions",
      title: "Cookies and sessions",
      partial: nil,
      waiting_on: "What the session cookie holds, how long it lasts, and the fact that " \
                  "there is no analytics or advertising cookie. The last part is the " \
                  "part worth saying."
    ),
    Section.new(
      slug: "children",
      title: "Children",
      partial: nil,
      waiting_on: "Whether under-18s may use the app at all, and what happens to an " \
                  "account that turns out to belong to one."
    ),
    Section.new(
      slug: "your-rights-and-hipaa",
      title: "Your rights, and whether HIPAA applies",
      partial: nil,
      waiting_on: "State privacy rights, breach notification, and the HIPAA question " \
                  "answered in plain words. Most people assume a health site is covered; " \
                  "a direct-to-patient tool that is not a covered entity usually is not. " \
                  "Leaving that unsaid lets people assume the stronger protection."
    ),
    Section.new(
      slug: "changes-and-contact",
      title: "Changes and contact",
      partial: "pages/privacy/changes_and_contact",
      waiting_on: nil
    )
  ].freeze

  class << self
    def sections = SECTIONS

    def unwritten = SECTIONS.reject(&:written?)
  end
end

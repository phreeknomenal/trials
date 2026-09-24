import { Controller } from "@hotwired/stimulus"

// Filters the questions already on the page. The FAQ is one list of thirteen
// entries rendered from Faq::ENTRIES, so there is nothing to fetch: hiding the
// non-matches is both faster than a round trip and keeps every <details> in the
// open or closed state the reader left it in.
//
// The box is wired rather than decorative on purpose. The design board drew a
// search field with a Search button, and an input that looks like it filters and
// does nothing is the same bug as a data-controller naming a controller that was
// never written: no error, correct-looking markup, nothing happens.
export default class extends Controller {
  static targets = ["input", "entry", "category", "empty", "status"]

  filter() {
    const query = this.inputTarget.value.trim().toLowerCase()

    let matches = 0

    this.entryTargets.forEach((entry) => {
      const hit = query === "" || this.matches(entry, query)
      entry.hidden = !hit
      if (hit) matches += 1

      // An open answer whose question has just been filtered out would otherwise
      // come back open when the query is cleared, which reads as the page
      // rearranging itself.
      if (!hit) entry.open = false
    })

    // A category heading with every question hidden under it is a heading over
    // nothing, so it goes too.
    this.categoryTargets.forEach((category) => {
      const visible = category.querySelectorAll("[data-faq-filter-target='entry']:not([hidden])")
      category.hidden = visible.length === 0
    })

    this.emptyTarget.hidden = matches > 0 || query === ""
    this.announce(query, matches)
  }

  matches(entry, query) {
    const question = entry.dataset.question || ""
    const answer = entry.dataset.answer || ""

    return question.includes(query) || answer.includes(query)
  }

  // role="status" on the target, so a screen reader hears the count change. The
  // visual result of a filter is obvious; the audible one is not.
  announce(query, matches) {
    if (query === "") {
      this.statusTarget.textContent = ""
      return
    }

    this.statusTarget.textContent =
      matches === 1 ? "1 question matches" : `${matches} questions match`
  }
}

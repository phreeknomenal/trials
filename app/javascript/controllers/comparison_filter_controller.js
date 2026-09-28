import { Controller } from "@hotwired/stimulus"

// Hides the rows where the studies agree, so the comparison shows only what a
// comparison is for.
//
// The checkbox renders unchecked and this checks it on connect. With no
// JavaScript the markup and the table then agree that everything is shown,
// rather than a checked box sitting above an unfiltered table.
export default class extends Controller {
  static targets = ["checkbox", "row", "heading", "empty"]

  connect() {
    if (this.hasCheckboxTarget) this.checkboxTarget.checked = true
    this.apply()
  }

  toggle() {
    this.apply()
  }

  apply() {
    const only = this.hasCheckboxTarget && this.checkboxTarget.checked
    let shown = 0

    this.rowTargets.forEach((row) => {
      const hide = only && row.dataset.differs !== "true"
      row.hidden = hide
      if (!hide) shown += 1
    })

    // A group heading with every row under it hidden is a label for nothing.
    this.headingTargets.forEach((heading) => {
      heading.hidden = !this.rowTargets.some(
        (row) => row.dataset.group === heading.dataset.group && !row.hidden
      )
    })

    if (this.hasEmptyTarget) this.emptyTarget.hidden = shown > 0
  }
}

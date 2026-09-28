import { Controller } from "@hotwired/stimulus"

// Hides the rows where the studies agree, so the comparison shows only what a
// comparison is for.
//
// It starts off. With the filter on, every visible row is one that differs, so
// the DIFFERS badge on each of them says nothing and the reader loses the
// denominator the summary line promises: "rows where the 3 differ are marked"
// only reads as a claim if the unmarked ones are on screen too.
//
// The board draws the box ticked, but draws a table with unmarked rows in it,
// so the board is not consistent with itself here. Making the control actually
// work is what exposed that.
export default class extends Controller {
  static targets = ["checkbox", "row", "heading", "empty"]

  connect() {
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

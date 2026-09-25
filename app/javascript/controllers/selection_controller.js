import { Controller } from "@hotwired/stimulus"

// The one selection model for the saved studies list.
//
// There were two before, and they did not share state. A "Select All" checkbox
// with a "Mark as" dropdown, which had no endpoint and no JavaScript and so had
// never done anything at all, and a separate set of checkboxes inside a compare
// form. Two sets of boxes on one page, answering the same question, one of them
// decorative.
//
// Now there is one set. The toolbar appears when something is selected and
// carries both actions, so a selection means the same thing whichever button
// you press.
export default class extends Controller {
  static targets = ["checkbox", "toolbar", "count", "compare", "compareLabel", "statusForm", "selectAll"]

  connect() {
    this.update()
  }

  toggleAll() {
    this.checkboxTargets.forEach((box) => { box.checked = this.selectAllTarget.checked })
    this.update()
  }

  update() {
    const selected = this.selected()

    this.toolbarTarget.hidden = selected.length === 0

    if (this.hasCountTarget) {
      this.countTarget.textContent =
        selected.length === 1 ? "1 study selected" : `${selected.length} studies selected`
    }

    if (this.hasSelectAllTarget) {
      this.selectAllTarget.checked =
        selected.length > 0 && selected.length === this.checkboxTargets.length
      this.selectAllTarget.indeterminate =
        selected.length > 0 && selected.length < this.checkboxTargets.length
    }

    // Comparing needs at least two, and the page caps it at three. Saying so on
    // the button beats letting someone press it and be told afterwards.
    if (this.hasCompareTarget) {
      const comparable = selected.length >= 2 && selected.length <= 3
      this.compareTarget.disabled = !comparable
      if (this.hasCompareLabelTarget) {
        this.compareLabelTarget.textContent =
          selected.length > 3 ? "Compare up to 3" : `Compare these ${selected.length}`
      }
    }

    this.syncHiddenIds(selected)
  }

  clear() {
    this.checkboxTargets.forEach((box) => { box.checked = false })
    this.update()
  }

  selected() {
    return this.checkboxTargets.filter((box) => box.checked)
  }

  // Both forms submit the same ids. They are mirrored into hidden inputs rather
  // than read from the checkboxes, because the checkboxes live in the list and
  // the forms live in the toolbar above it.
  syncHiddenIds(selected) {
    this.statusFormTargets.forEach((form) => {
      form.querySelectorAll("[data-selection-id]").forEach((input) => input.remove())

      selected.forEach((box) => {
        const input = document.createElement("input")
        input.type = "hidden"
        input.name = form.dataset.selectionParam || "saved_trial_ids[]"
        input.value = box.value
        input.setAttribute("data-selection-id", "")
        form.appendChild(input)
      })
    })
  }
}

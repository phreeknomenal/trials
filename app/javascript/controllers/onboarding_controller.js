import {Controller} from "@hotwired/stimulus"

// Keyboard behaviour for the wizard. The HTML autofocus attribute only fires on
// a full document load, and Turbo navigates between steps without one, so focus
// is set on connect instead.
export default class extends Controller {
  static targets = ["firstField"]

  connect() {
    this.focusFirstField()
  }

  focusFirstField() {
    if (!this.hasFirstFieldTarget) return
    // Skip on touch devices, where forcing focus opens the keyboard over the
    // question the user has not read yet.
    if (window.matchMedia("(pointer: coarse)").matches) return

    this.firstFieldTarget.focus()
  }

  // Enter advances the step. Textareas keep their newline, and the check that
  // the form is valid lets the browser show its own validation message rather
  // than submitting a step that will only bounce back.
  submitOnEnter(event) {
    if (event.key !== "Enter") return
    if (event.target.tagName === "TEXTAREA") return

    const form = this.element.querySelector("form")
    if (!form) return

    event.preventDefault()
    form.requestSubmit()
  }
}

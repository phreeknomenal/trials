import { Controller } from "@hotwired/stimulus"

// Submits the form when a control inside it changes.
//
// Used by the saved-study pipeline, where picking a status from the select is
// the whole action and pressing a second button to confirm it is a step nobody
// wants. The button stays in the markup and stays visible, so the control still
// works with JavaScript off or broken; this only removes a click when it runs.
export default class extends Controller {
  submit(event) {
    // A blank option is the prompt ("Something else…"), not a choice.
    if (event.target.value === "") return

    this.element.requestSubmit()
  }
}

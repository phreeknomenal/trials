import {Controller} from "@hotwired/stimulus"

// Removes the message rather than hiding it, so a dismissed flash does not stay
// in the accessibility tree announcing itself to a screen reader.
export default class extends Controller {
  dismiss() {
    this.element.remove()
  }
}

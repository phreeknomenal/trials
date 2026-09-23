import { Controller } from "@hotwired/stimulus"

// Shows the photo someone just chose, in place of whatever was there before.
//
// The markup this replaces declared data-controller="upload-photos" and six
// targets against a controller that was never written, so choosing a file did
// nothing visible at all: no preview, no filename, no way to tell whether the
// upload had been accepted.
export default class extends Controller {
  static targets = ["input", "preview", "placeholder", "filename", "remove"]

  connect() {
    this.objectUrl = null
  }

  // Revoked on disconnect and before each replacement. An object URL holds the
  // file in memory until it is released, and this control can be used repeatedly.
  disconnect() {
    this.#releaseObjectUrl()
  }

  select() {
    const file = this.inputTarget.files[0]
    if (!file) return

    this.#releaseObjectUrl()
    this.objectUrl = URL.createObjectURL(file)

    this.previewTarget.src = this.objectUrl
    this.previewTarget.hidden = false
    if (this.hasPlaceholderTarget) this.placeholderTarget.hidden = true
    if (this.hasRemoveTarget) this.removeTarget.hidden = false
    if (this.hasFilenameTarget) this.filenameTarget.textContent = file.name
  }

  // Clears the chosen file rather than the saved one. A photo already on the
  // account is removed by saving the step with the field empty.
  remove() {
    this.inputTarget.value = ""
    this.#releaseObjectUrl()

    this.previewTarget.removeAttribute("src")
    this.previewTarget.hidden = true
    if (this.hasPlaceholderTarget) this.placeholderTarget.hidden = false
    if (this.hasRemoveTarget) this.removeTarget.hidden = true
    if (this.hasFilenameTarget) this.filenameTarget.textContent = ""
  }

  #releaseObjectUrl() {
    if (!this.objectUrl) return

    URL.revokeObjectURL(this.objectUrl)
    this.objectUrl = null
  }
}

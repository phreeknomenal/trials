import {Controller} from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["modal"]

  connect() {
    // Auto-show modal if profile is incomplete
    if (this.element.dataset.profileIncomplete === "true") {
      this.showModal()
    }
  }

  showModal() {
    if (this.hasModalTarget) {
      this.modalTarget.classList.remove("hidden")
      this.modalTarget.style.display = "flex"
    }
  }

  closeModal(event) {
    if (event) {
      event.preventDefault()
    }
    if (this.hasModalTarget) {
      this.modalTarget.classList.add("hidden")
      this.modalTarget.style.display = "none"
    }
  }

  handleSuccess(event) {
    // Called after successful turbo stream response
    const response = event.detail.fetchResponse
    if (response && response.succeeded) {
      this.closeModal()
    }
  }
}


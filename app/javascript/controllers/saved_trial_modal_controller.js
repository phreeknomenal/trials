import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["modal", "form"]
  static values = {
    url: String,
  }

  open(event) {
    event.preventDefault()
    const trialId = event.currentTarget.dataset.trialId || event.currentTarget.dataset.savedTrialId
    if (trialId) {
      this.loadForm(trialId)
    }
  }

  async loadForm(trialId) {
    try {
      const response = await fetch(`/saved_trials/${trialId}/edit`, {
        headers: {
          "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content,
        },
      })

      if (response.ok) {
        const html = await response.text()
        if (this.hasModalTarget) {
          this.modalTarget.innerHTML = html
          this.showModal()
        }
      }
    } catch (error) {
      console.error("Error loading form:", error)
    }
  }

  showModal() {
    if (this.hasModalTarget) {
      this.modalTarget.classList.remove("hidden")
      this.modalTarget.classList.add("fixed", "inset-0", "bg-black", "bg-opacity-50", "flex", "items-center", "justify-center", "z-50")
    }
  }

  close(event) {
    event.preventDefault()
    if (this.hasModalTarget) {
      this.modalTarget.classList.add("hidden")
      this.modalTarget.classList.remove("fixed", "inset-0", "bg-black", "bg-opacity-50", "flex", "items-center", "justify-center", "z-50")
    }
  }

  submit(event) {
    event.preventDefault()
    if (this.hasFormTarget) {
      this.formTarget.submit()
    }
  }
}


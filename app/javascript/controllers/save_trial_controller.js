import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["button", "form", "outlineIcon", "solidIcon", "label"]
  static values = {
    nctId: String,
    trialTitle: String,
    isSaved: Boolean,
    matchScore: String,
    trialData: String,
    savedTrialId: Number,
  }

  connect() {
    this.updateButtonState()
  }

  async toggleSave(event) {
    event.preventDefault()

    if (this.isSavedValue) {
      await this.unsaveTrial()
    } else {
      await this.saveTrial()
    }
  }

  async saveTrial() {
    const trialData = this.trialDataValue ? JSON.parse(this.trialDataValue) : {}
    
    const payload = {
      saved_trial: {
        nct_id: this.nctIdValue,
        trial_title: this.trialTitleValue,
        match_score: this.matchScoreValue || null,
        phase: trialData.phase,
        study_type: trialData.study_type,
        trial_status: trialData.status,
        min_age: trialData.min_age,
        max_age: trialData.max_age,
        enrollment_count: trialData.enrollment_count,
        start_date: trialData.start_date,
        completion_date: trialData.completion_date,
        sponsor: trialData.sponsor,
        summary: trialData.summary,
      }
    }

    try {
      const response = await fetch("/saved_trials", {
        method: "POST",
        body: JSON.stringify(payload),
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content,
        },
      })

      console.log("Save response status:", response.status)
      const responseText = await response.text()
      console.log("Save response body:", responseText)

      if (response.ok) {
        this.isSavedValue = true
        this.updateButtonState()
        this.showNotification("Trial saved successfully!", "success")
      } else {
        try {
          const data = JSON.parse(responseText)
          this.showNotification(data.error || `Failed to save trial (${response.status})`, "error")
        } catch {
          this.showNotification(`Failed to save trial (${response.status}): ${responseText.substring(0, 100)}`, "error")
        }
      }
    } catch (error) {
      console.error("Error saving trial:", error)
      this.showNotification(`An error occurred while saving: ${error.message}`, "error")
    }
  }

  async unsaveTrial() {
    const savedTrialId = this.getSavedTrialId()

    if (!savedTrialId) {
      console.error("Could not find saved trial ID")
      return
    }

    try {
      const response = await fetch(`/saved_trials/${savedTrialId}`, {
        method: "DELETE",
        headers: {
          "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content,
        },
      })

      if (response.ok) {
        this.isSavedValue = false
        this.updateButtonState()
        this.showNotification("Trial removed from saved", "success")
      } else {
        this.showNotification("Failed to remove trial", "error")
      }
    } catch (error) {
      console.error("Error removing trial:", error)
      this.showNotification("An error occurred while removing", "error")
    }
  }

  getSavedTrialId() {
    return this.savedTrialIdValue ?? null
  }

  // Toggles visibility and attributes rather than rewriting innerHTML. The old
  // version pasted in a hardcoded SVG, which meant the icon existed in three
  // places and any change had to be made in all of them.
  updateButtonState() {
    if (!this.hasButtonTarget) return

    const button = this.buttonTarget
    const isSaved = this.isSavedValue

    button.setAttribute("aria-pressed", String(isSaved))
    button.classList.toggle("saved", isSaved)

    if (this.hasOutlineIconTarget) this.outlineIconTarget.classList.toggle("hidden", isSaved)
    if (this.hasSolidIconTarget) this.solidIconTarget.classList.toggle("hidden", !isSaved)
    if (this.hasLabelTarget) this.labelTarget.textContent = isSaved ? "Saved" : "Save Trial"

    const saved = ["border-blue-500", "bg-blue-50", "text-blue-700", "hover:bg-blue-100"]
    const unsaved = ["border-gray-300", "bg-white", "text-gray-700", "hover:bg-gray-50"]

    button.classList.remove(...(isSaved ? unsaved : saved))
    button.classList.add(...(isSaved ? saved : unsaved))
  }

  showNotification(message, type) {
    // Create a simple notification
    const notification = document.createElement("div")
    notification.className = `fixed top-4 right-4 p-4 rounded-lg text-white ${
      type === "success" ? "bg-green-500" : "bg-red-500"
    }`
    notification.textContent = message

    document.body.appendChild(notification)

    setTimeout(() => {
      notification.remove()
    }, 3000)
  }
}


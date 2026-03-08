import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["button", "form"]
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

  updateButtonState() {
    if (!this.hasButtonTarget) return

    const button = this.buttonTarget
    const isSaved = this.isSavedValue

    if (isSaved) {
      button.classList.add("saved")
      button.innerHTML = '<svg class="w-5 h-5 inline mr-2" fill="currentColor" viewBox="0 0 20 20"><path d="M5 4a2 2 0 012-2h6a2 2 0 012 2v14l-5-2.5L5 18V4z"></path></svg>Saved'
      button.classList.remove("border-gray-300", "text-gray-700", "hover:bg-gray-50")
      button.classList.add("border-blue-500", "bg-blue-50", "text-blue-700")
    } else {
      button.classList.remove("saved")
      button.innerHTML = '<svg class="w-5 h-5 inline mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 5a2 2 0 012-2h6a2 2 0 012 2v14l-5-2.5L5 19V5z"></path></svg>Save Trial'
      button.classList.add("border-gray-300", "text-gray-700", "hover:bg-gray-50")
      button.classList.remove("border-blue-500", "bg-blue-50", "text-blue-700")
    }
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


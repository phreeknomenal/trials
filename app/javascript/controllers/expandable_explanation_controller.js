import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["explanation"]

  toggle(event) {
    event.preventDefault()
    const button = event.currentTarget
    const explanation = this.element.querySelector('[data-expandable-explanation-target="explanation"]')

    if (!explanation) return

    const isExpanded = button.getAttribute("aria-expanded") === "true"

    if (isExpanded) {
      this.collapse(button, explanation)
    } else {
      this.expand(button, explanation)
    }
  }

  expand(button, explanation) {
    explanation.classList.remove("hidden")
    button.setAttribute("aria-expanded", "true")

    // Smooth height animation
    explanation.style.maxHeight = "0px"
    explanation.style.overflow = "hidden"
    explanation.style.transition = "max-height 0.3s ease-out"

    // Trigger reflow to apply initial state
    void explanation.offsetHeight

    // Animate to full height
    explanation.style.maxHeight = explanation.scrollHeight + "px"
  }

  collapse(button, explanation) {
    button.setAttribute("aria-expanded", "false")

    // Animate to zero height
    explanation.style.maxHeight = "0px"
    explanation.style.overflow = "hidden"

    // After animation, hide the element
    setTimeout(() => {
      explanation.classList.add("hidden")
      explanation.style.maxHeight = ""
      explanation.style.overflow = ""
      explanation.style.transition = ""
    }, 300)
  }
}

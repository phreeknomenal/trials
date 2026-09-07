import {Controller} from "@hotwired/stimulus"

// Header navigation for viewports below the lg breakpoint, where the desktop
// menu is hidden. The panel is toggled with the hidden attribute rather than a
// class, so it leaves the accessibility tree entirely when closed instead of
// staying focusable behind a display rule.
export default class extends Controller {
  static targets = ["panel", "trigger", "openIcon", "closeIcon"]

  connect() {
    this.close()
    this.closeForCache = () => this.close()
    document.addEventListener("turbo:before-cache", this.closeForCache)
  }

  disconnect() {
    document.removeEventListener("turbo:before-cache", this.closeForCache)
  }

  toggle() {
    this.open ? this.close() : this.show()
  }

  show() {
    this.panelTarget.hidden = false
    this.triggerTarget.setAttribute("aria-expanded", "true")
    this.triggerTarget.setAttribute("aria-label", "Close menu")
    this.openIconTarget.classList.add("hidden")
    this.closeIconTarget.classList.remove("hidden")
  }

  close() {
    this.panelTarget.hidden = true
    this.triggerTarget.setAttribute("aria-expanded", "false")
    this.triggerTarget.setAttribute("aria-label", "Open menu")
    this.openIconTarget.classList.remove("hidden")
    this.closeIconTarget.classList.add("hidden")
  }

  // Escape returns focus to the trigger. Without that a keyboard user is left
  // at the bottom of a panel that no longer exists.
  closeOnEscape() {
    if (!this.open) return

    this.close()
    this.triggerTarget.focus()
  }

  closeOnOutsideClick(event) {
    if (!this.open) return
    if (this.element.contains(event.target)) return

    this.close()
  }

  get open() {
    return this.hasPanelTarget && !this.panelTarget.hidden
  }
}

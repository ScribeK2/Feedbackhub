import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dialog"]

  open(event) {
    const modalId = event.params.id
    const dialog = document.getElementById(modalId)
    if (dialog) {
      dialog.showModal()
    }
  }

  close(event) {
    const dialog = event.target.closest("dialog")
    if (dialog) {
      dialog.close()
    }
  }

  backdropClose(event) {
    const dialog = event.target
    if (event.target === dialog) {
      dialog.close()
    }
  }
}

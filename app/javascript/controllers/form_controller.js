import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["templateSelect"]

  switchTemplate(event) {
    const templateId = event.target.value
    if (templateId) {
      this.element.requestSubmit()
    }
  }
}

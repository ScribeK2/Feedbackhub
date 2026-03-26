import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["select", "input"]

  toggle(event) {
    const select = event.target
    const wrapper = select.closest("[data-other-field-target='wrapper']")
    if (!wrapper) return

    const inputDiv = wrapper.querySelector("[data-other-field-target='input']")
    if (!inputDiv) return

    const input = inputDiv.querySelector("input")

    if (select.value === "Other") {
      inputDiv.classList.remove("hidden")
      if (input) input.required = true
    } else {
      inputDiv.classList.add("hidden")
      if (input) {
        input.required = false
        input.value = ""
      }
    }
  }
}

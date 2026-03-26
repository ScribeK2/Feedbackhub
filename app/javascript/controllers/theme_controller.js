import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.applyTheme()
  }

  setTheme(event) {
    const button = event.currentTarget
    const theme = button.dataset.themeValue
    if (theme) {
      localStorage.setItem("theme", theme)
      this.applyTheme()
    }
  }

  applyTheme() {
    const theme = localStorage.getItem("theme") || "corporate"
    document.documentElement.setAttribute("data-theme", theme)
  }
}

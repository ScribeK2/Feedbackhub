import { Controller } from "@hotwired/stimulus"

const VALID = ["fh-light", "fh-dark"]
const LEGACY = { light: "fh-light", corporate: "fh-light", dark: "fh-dark", business: "fh-dark" }

export default class extends Controller {
  connect() {
    this.applyTheme()
  }

  setTheme(event) {
    const theme = event.currentTarget.dataset.themeValue
    if (VALID.includes(theme)) {
      localStorage.setItem("theme", theme)
      this.applyTheme()
    }
  }

  applyTheme() {
    let theme = localStorage.getItem("theme")
    if (LEGACY[theme]) {
      theme = LEGACY[theme]
      localStorage.setItem("theme", theme)
    }
    if (!VALID.includes(theme)) theme = "fh-light"
    document.documentElement.setAttribute("data-theme", theme)
  }
}

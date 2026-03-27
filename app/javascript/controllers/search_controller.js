import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "results"]

  submit() {
    clearTimeout(this.timeout)
    this.timeout = setTimeout(() => {
      const query = this.inputTarget.value.trim()
      if (query.length < 2) {
        this.resultsTarget.innerHTML = ""
        this.resultsTarget.classList.add("hidden")
        return
      }

      fetch(`/search?q=${encodeURIComponent(query)}`, {
        headers: { Accept: "text/vnd.turbo-stream.html" }
      })
        .then(r => r.text())
        .then(html => {
          this.resultsTarget.innerHTML = html
          this.resultsTarget.classList.remove("hidden")
        })
    }, 300)
  }

  close(event) {
    if (!this.element.contains(event.target)) {
      this.resultsTarget.classList.add("hidden")
    }
  }

  connect() {
    this.closeHandler = this.close.bind(this)
    document.addEventListener("click", this.closeHandler)
  }

  disconnect() {
    document.removeEventListener("click", this.closeHandler)
  }
}

import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "hidden", "badges", "suggestions", "badge"]

  handleKeydown(event) {
    if (event.key === "Enter" || event.key === ",") {
      event.preventDefault()
      this.addCurrentTag()
    }
  }

  search() {
    clearTimeout(this.searchTimeout)
    const query = this.inputTarget.value.trim()

    if (query.length < 1) {
      this.suggestionsTarget.classList.add("hidden")
      return
    }

    this.searchTimeout = setTimeout(() => {
      fetch(`/tags.json?q=${encodeURIComponent(query)}`)
        .then(r => r.json())
        .then(tags => this.showSuggestions(tags))
    }, 200)
  }

  showSuggestions(tags) {
    const existing = this.currentTags()
    const filtered = tags.filter(t => !existing.includes(t))

    if (filtered.length === 0) {
      this.suggestionsTarget.classList.add("hidden")
      return
    }

    this.suggestionsTarget.innerHTML = ""
    filtered.forEach(tag => {
      const btn = document.createElement("button")
      btn.type = "button"
      btn.className = "block w-full text-left px-3 py-2 hover:bg-base-200 text-sm"
      btn.textContent = tag
      btn.addEventListener("click", () => {
        this.addTag(tag)
        this.inputTarget.value = ""
        this.suggestionsTarget.classList.add("hidden")
      })
      this.suggestionsTarget.appendChild(btn)
    })
    this.suggestionsTarget.classList.remove("hidden")
  }

  addCurrentTag() {
    const value = this.inputTarget.value.trim().replace(/,/g, "").toLowerCase()
    if (value) {
      this.addTag(value)
      this.inputTarget.value = ""
      this.suggestionsTarget.classList.add("hidden")
    }
  }

  addTag(name) {
    const existing = this.currentTags()
    if (existing.includes(name)) return

    const badge = document.createElement("span")
    badge.className = "badge badge-outline gap-1"
    badge.dataset.tagInputTarget = "badge"
    badge.dataset.tagName = name
    badge.innerHTML = `${name} <button type="button" class="text-xs opacity-60 hover:opacity-100" data-action="click->tag-input#removeTag">&times;</button>`
    this.badgesTarget.appendChild(badge)

    this.updateHidden()
  }

  removeTag(event) {
    const badge = event.target.closest("[data-tag-name]")
    if (badge) {
      badge.remove()
      this.updateHidden()
    }
  }

  updateHidden() {
    this.hiddenTarget.value = this.currentTags().join(", ")
  }

  currentTags() {
    return this.badgeTargets.map(b => b.dataset.tagName)
  }
}

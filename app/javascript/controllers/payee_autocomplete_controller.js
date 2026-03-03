import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["payeeName", "payeeId", "dropdown"]

  connect() {
    this._outsideClick = this._handleOutsideClick.bind(this)
    document.addEventListener("click", this._outsideClick)
    this._debounceTimer = null
  }

  disconnect() {
    document.removeEventListener("click", this._outsideClick)
    clearTimeout(this._debounceTimer)
  }

  focusIn() {
    clearTimeout(this._debounceTimer)
    this._fetchResults()
  }

  search() {
    clearTimeout(this._debounceTimer)
    this._debounceTimer = setTimeout(() => this._fetchResults(), 300)
  }

  _fetchResults() {
    const term = this.payeeNameTarget.value.trim()

    fetch(`/payees.json?q=${encodeURIComponent(term)}`, {
      headers: { Accept: "application/json" }
    })
      .then(r => r.json())
      .then(payees => this._renderDropdown(payees, term))
  }

  _renderDropdown(payees, term) {
    const dropdown = this.dropdownTarget
    dropdown.innerHTML = ""

    if (payees.length === 0 && term.length === 0) {
      this._hideDropdown()
      return
    }

    payees.forEach(payee => {
      const item = document.createElement("div")
      item.className = "px-3 py-2 cursor-pointer text-sm hover:bg-white/10 transition-colors"
      item.style.color = "#E2E8F0"
      item.textContent = payee.name
      item.addEventListener("mousedown", e => {
        e.preventDefault()
        this._selectExisting(payee)
      })
      dropdown.appendChild(item)
    })

    if (term.length > 0) {
      const createItem = document.createElement("div")
      createItem.className = "px-3 py-2 cursor-pointer text-sm hover:bg-white/10 transition-colors border-t"
      createItem.style.cssText = "color: #6C63FF; border-color: #2A2F45;"
      createItem.textContent = `+ Create "${term}"`
      createItem.addEventListener("mousedown", e => {
        e.preventDefault()
        this._selectNew(term)
      })
      dropdown.appendChild(createItem)
    }

    dropdown.style.display = "block"
  }

  _selectExisting(payee) {
    this.payeeNameTarget.value = payee.name
    this.payeeIdTarget.value = payee.id
    this._hideDropdown()
  }

  _selectNew(term) {
    this.payeeNameTarget.value = term
    this.payeeIdTarget.value = ""
    this._hideDropdown()
  }

  _hideDropdown() {
    this.dropdownTarget.style.display = "none"
    this.dropdownTarget.innerHTML = ""
  }

  _handleOutsideClick(event) {
    if (!this.element.contains(event.target)) {
      this._hideDropdown()
    }
  }
}

import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["viewState", "editState", "name", "input"]
  static values = { url: String }

  edit() {
    this.inputTarget.value = this.nameTarget.textContent.trim()
    this.viewStateTarget.style.display = "none"
    this.editStateTarget.style.display = "flex"
    this.editStateTarget.style.flexDirection = "column"
    this.inputTarget.focus()
    this.inputTarget.select()
  }

  cancel() {
    this.editStateTarget.style.display = "none"
    this.viewStateTarget.style.display = "flex"
  }

  save() {
    const name = this.inputTarget.value.trim()
    if (!name) return

    fetch(this.urlValue, {
      method: "PATCH",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content,
        "Accept": "application/json"
      },
      body: JSON.stringify({ payee: { name } })
    })
      .then(r => r.json())
      .then(data => {
        if (data.name) {
          this.nameTarget.textContent = data.name
          this.cancel()
        }
      })
  }
}

import { Controller } from "@hotwired/stimulus"
import flatpickr from "flatpickr"

export default class extends Controller {
  connect() {
    this.picker = flatpickr(this.element, {
      dateFormat: "Y-m-d",
    })
  }

  disconnect() {
    this.picker?.destroy()
  }
}

import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["spinner", "content"]

  connect() {
    this.hideSpinner()
  }

  showSpinner() {
    this.spinnerTarget.classList.remove("hidden")
    this.contentTarget.classList.add("hidden")
  }

  hideSpinner() {
    this.spinnerTarget.classList.add("hidden")
    this.contentTarget.classList.remove("hidden")
  }
}

import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.element.querySelector("button").addEventListener("click", () => {
      this.element.remove()
    })
  }
}

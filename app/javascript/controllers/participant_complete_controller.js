import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="participant-complete"
export default class extends Controller {
  connect() {
    document.addEventListener("autocomplete.change", this.autocomplete.bind(this))
  }

  autocomplete(event) {
    console.log(event);
  }
}

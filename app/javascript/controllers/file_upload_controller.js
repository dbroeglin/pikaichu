import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "name", "file" ]

  connect() {
    this.fileTarget.onchange = () => {
      this.change();
    }
  }

  change() {
    if (this.fileTarget.files.length > 0) {
      this.nameTarget.textContent = this.fileTarget.files[0].name;
    }
  }

}

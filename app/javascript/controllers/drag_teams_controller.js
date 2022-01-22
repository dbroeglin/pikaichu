import { Controller } from "@hotwired/stimulus"
import { Sortable } from "sortablejs"

// Connects to data-controller="sortable-teams"
export default class extends Controller {
  static targets = ["left", "right"];

  connect() {
    console.log("Connecting...")
    this.csrf = document.querySelector("meta[name='csrf-token']").getAttribute("content");

    for (var i = 0; i < this.leftTargets.length; i++) {
      new Sortable(this.leftTargets[i], {
        group: 'shared',
        animation: 150,
       // fallbackOnBody: true,
        swapThreshold: 0.65,
        onEnd: this.endLeft.bind(this)
      });
    }

    Sortable.create(this.rightTarget, {
      group: 'shared',
      animation: 150,
      onEnd: this.endRight.bind(this)
    });
  }

  endLeft(event) {
    console.log("End Left: ", event);
    console.log(" From ", event.from, " to ", event.to);
  }

  endRight(event) {
    console.log("End Right: ", event);
    console.log(" From ", event.from, " to ", event.to);
  }
}

import { Controller } from "@hotwired/stimulus"
import Sortable from "sortablejs"

export default class extends Controller {
  static targets = ["left", "right"];

  connect() {
    console.log("Connecting...")
    this.csrf = document.querySelector("meta[name='csrf-token']").getAttribute("content");

    Sortable.create(this.leftTarget, {
      group: 'shared',
      animation: 150,
      onEnd: this.endLeft.bind(this)
    });

    for (var i = 0; i < this.rightTargets.length; i++) {
      new Sortable(this.rightTargets[i], {
        group: 'shared',
        animation: 150,
       // fallbackOnBody: true,
        swapThreshold: 0.65,
        onEnd: this.endRight.bind(this)
      });
    }

  }

  endLeft(event) {
    console.log("End Left: ", event, " From ", event.from, " to ", event.to);

    let participantId = event.item.dataset.id;
    let teamId = event.to.dataset.id;
    let index = event.newIndex + 1;

    console.log("Dragged participant ", participantId, " to team ", teamId, " in position ", index);

    this.moveParticipant(participantId, teamId, index);
  }

  endRight(event) {
    console.log("End Right: ", event, " From ", event.from, " to ", event.to);

    let participantId = event.item.dataset.id;
    let teamId = event.to.dataset.id;
    let index = event.newIndex + 1;

    console.log("Dragged participant ", participantId, " to team ", teamId, " in position ", index);

    this.moveParticipant(participantId, teamId, index);
  }

  moveParticipant(participantId, teamId, index) {
    let data = new FormData()

    data.append("participant_id", participantId);
    if (undefined !== teamId) {
      data.append("team_id", teamId);
      data.append("index", index);
    }

    fetch(this.data.get("url"), {
      method: 'PATCH',
      body: data,
      headers: {
        'X-CSRF-Token': this.csrf
      }
    })
      .then(response => response.text())
      .then(html => {
        //this.element.innerHTML = html
      });
  }
}

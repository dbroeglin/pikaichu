import { Controller } from "@hotwired/stimulus"
import { Sortable } from "sortablejs"

// Connects to data-controller="drag"
export default class extends Controller {


  connect() {
    this.csrf = document.querySelector("meta[name='csrf-token']").getAttribute("content");
    Sortable.create(this.element, {
      onEnd: this.end.bind(this)
    });
  }

  end(event) {
    console.log(event);
    let id = event.item.dataset.id
    let data = new FormData()

    data.append("index", event.newIndex + 1);

    fetch(this.data.get("url").replace(':id', id), {
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

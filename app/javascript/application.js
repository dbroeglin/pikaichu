// Entry point for the build script in your package.json
import "@hotwired/turbo-rails"
import "./controllers"
import "./bulma.js"

// Keep for link_to DELETE
import Rails from "@rails/ujs"
Rails.start()

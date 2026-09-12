# Pin npm packages by running ./bin/importmap

pin "application", preload: true
pin "@hotwired/turbo", to: "turbo.min.js", preload: true # @8.0.19
pin "@hotwired/stimulus", to: "stimulus.min.js", preload: true # @3.2.1
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"

# Vendored packages
pin "sortablejs", to: "sortablejs.js" # @1.15.6
pin "stimulus-autocomplete", to: "stimulus-autocomplete.js" # @3.1.0

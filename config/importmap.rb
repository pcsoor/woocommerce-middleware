# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "@hotwired--turbo-rails.js" # @2.1.0
pin "@hotwired/stimulus", to: "@hotwired--stimulus.js" # @3.2.2
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js", preload: true
pin "@stimulus-components/dropdown", to: "@stimulus-components--dropdown.js"
pin "stimulus-use"

# Pin all controllers
pin_all_from "app/javascript/controllers", under: "controllers"

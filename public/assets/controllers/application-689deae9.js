import { Application } from "@hotwired/stimulus"
import Dropdown from "@stimulus-components/dropdown"

const application = Application.start()

application.debug = false
window.Stimulus = application
application.register('dropdown', Dropdown)

export { application }

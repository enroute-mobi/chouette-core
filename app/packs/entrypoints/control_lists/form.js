import Alpine from 'alpinejs'

window.Alpine = Alpine

import Store from '../../src/control_lists/store'

Alpine.store('controlList', new Store)

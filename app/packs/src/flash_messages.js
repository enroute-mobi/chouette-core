import Alpine from 'alpinejs'
import { uniqueId } from 'lodash'

window.Alpine = Alpine

const bootstrapClassFor = type => {
  switch(type) {
    case 'success':
      return 'alert-success'
    case 'warning':
      return 'alert-warning'
    case 'error':
      return 'alert-danger'
  }
}
Alpine.store('flash', {
  ready: true,
  messages: new Map,
  add({ type, text }) {
    const id = uniqueId('flash_')
    const bootstrapClass = bootstrapClassFor(type)
    const icon = type == 'warning' ? 'fa-exclamation-triangle' : 'fa-exclamation-circle'
  
    this.messages = this.messages.set(id, { type, text, bootstrapClass, icon, show: false })
    
    this.show(id)
    setTimeout(() => { this.remove(id) }, 5000)
  },
  show(id) {
    setTimeout(() => { this.messages.get(id).show = true }, 100)
  },
  remove(id) {
    setTimeout(() => { this.messages.get(id).show = false }, 100)
    setTimeout(() => { this.messages.delete(id) }, 3000)
  }
})

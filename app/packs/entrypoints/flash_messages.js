import Alpine from 'alpinejs'
import { reject, uniqueId } from 'lodash'

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
  messages: [],
  add({ type, text }) {
    const id = uniqueId('flash_')
    const bootstrapClass = bootstrapClassFor(type)
    const icon = type == 'warning' ? 'fa-exclamation-triangle' : 'fa-exclamation-circle'
  
    this.messages.push({ id, type, text, bootstrapClass, icon })

    setTimeout(() => this.remove(id), 5000)
  },
  remove(id) {
    this.messages = reject(this.messages, ['id', id])
  }
})

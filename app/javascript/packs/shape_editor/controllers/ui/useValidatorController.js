import { useEffect } from 'react'

import store from '../../shape.store'
import eventEmitter from '../../shape.event-emitter'

// Custom hook which responsability is to fetch a save (create/update) a shape object
export default function useValidatorController() {
  // Check waypoints collection before authorizing delete action
  const validatesLengthOfWaypoints = (length = 2) => {
    return eventEmitter.on('map:delete-waypoint-request', async waypoint => {
      store.getState(({ waypoints }) => {
        if (waypoints.getLength() == length) {
          window.Spruce.stores.flash.add({ type: 'warning', text: I18n.t('shapes.errors.must_have_enough_waypoints') })
        } else {
          eventEmitter.emit('map:delete-waypoint', waypoint)
        }
      })
    })

  }
  useEffect(() => {
    const sub = validatesLengthOfWaypoints()
    return () => sub.unsubscribe()
  }, [])
}
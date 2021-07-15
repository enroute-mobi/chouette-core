import React, { useEffect } from 'react'
import AddJourneyPattern from '../containers/AddJourneyPattern'
import Navigate from '../containers/Navigate'
import Modal from '../containers/Modal'
import ConfirmModal from '../containers/ConfirmModal'
import CancelJourneyPattern from '../containers/CancelJourneyPattern'
import SaveJourneyPattern from '../containers/SaveJourneyPattern'
import JourneyPatternList from '../containers/JourneyPatternList'
import RouteMap from './RouteMap'

const App = () => {
  // Add a flash message if a shape was previoulsy created/updated
  useEffect(() => {
    const { sessionStorage } = window
    const key = 'previousShapeAction'
    const resource_name = I18n.t('activerecord.models.shape.one')

    switch(sessionStorage.getItem(key)) {
      case 'shape-created':
        window.Spruce.stores.flash.add({ type: 'success', text: I18n.t('flash.actions.create.notice', { resource_name } ) })
        break
      case 'shape-updated':
        window.Spruce.stores.flash.add({ type: 'success', text: I18n.t('flash.actions.update.notice', { resource_name } ) })
        break
    }

    sessionStorage.removeItem(key)
  }, [])

  return (
    <div>
    <Navigate />
    <JourneyPatternList />
    <Navigate />
    <AddJourneyPattern />
    <CancelJourneyPattern />
    <SaveJourneyPattern />
    <ConfirmModal />
    <Modal/>
    {/* That map has been deactivated until further specs */}
    {/* <h4 className="underline">{I18n.t('lines.show.map')}</h4>
    <RouteMap/> */}
  </div>
  )
}

export default App

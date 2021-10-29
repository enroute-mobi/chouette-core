import React, { useEffect } from 'react'
import AddJourneyPattern from '../containers/AddJourneyPattern'
import Navigate from '../containers/Navigate'
import Modal from '../containers/Modal'
import ConfirmModal from '../containers/ConfirmModal'
import CancelJourneyPattern from '../containers/CancelJourneyPattern'
import SaveJourneyPattern from '../containers/SaveJourneyPattern'
import JourneyPatternList from '../containers/JourneyPatternList'

const App = () => {
  // Add a flash message if a shape was previoulsy created/updated/unassociated
  useEffect(() => {
    const { flash } = window.Spruce.stores
    const { sessionStorage } = window

    const key = 'previousAction'
    const previousAction = sessionStorage.getItem(key)

    if (previousAction) {
      const { resource, action, status } = JSON.parse(previousAction)

      flash.add({
        type: 'success',
        text: I18n.t(`flash.actions.${action}.${status}`, {
          resource_name: I18n.t(`activerecord.models.${resource}.one`)
        })
      })

      sessionStorage.removeItem(key) 
    }
  }, [])

  useEffect(() => {
    document.dispatchEvent(new Event('submitMover'))
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

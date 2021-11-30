import React from 'react'
import AddJourneyPattern from '../containers/AddJourneyPattern'
import Navigate from '../containers/Navigate'
import Modal from '../containers/Modal'
import ConfirmModal from '../containers/ConfirmModal'
import CancelJourneyPattern from '../containers/CancelJourneyPattern'
import SaveJourneyPattern from '../containers/SaveJourneyPattern'
import JourneyPatternList from '../containers/JourneyPatternList'

import { useFlashMessage, useSubmitMover } from '../../helpers/hooks'

const App = () => {
  useFlashMessage()
  useSubmitMover()

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

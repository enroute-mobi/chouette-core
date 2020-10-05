import React from 'react'
import AddJourneyPattern from '../containers/AddJourneyPattern'
import Navigate from '../containers/Navigate'
import Modal from '../containers/Modal'
import ConfirmModal from '../containers/ConfirmModal'
import CancelJourneyPattern from '../containers/CancelJourneyPattern'
import SaveJourneyPattern from '../containers/SaveJourneyPattern'
import JourneyPatternList from '../containers/JourneyPatternList'
import RouteMapper from './RouteMapper'


const App = () => (
  <div>
    <Navigate />
    <JourneyPatternList />
    <Navigate />
    <AddJourneyPattern />
    <CancelJourneyPattern />
    <SaveJourneyPattern />
    <ConfirmModal />
    <Modal/>
    <RouteMapper/>
  </div>
)

export default App

import React from 'react'
import { BrowserRouter, Route } from 'react-router-dom'
import { SWRConfig } from 'swr'
import ShapeEditorMap from './ShapeEditorMap'

const options = {
  fetcher: url => fetch(url, { headers: { 'Accept': 'application/json' } }).then(res => res.json()),
  onError: (error, key) => { console.warn(`${key} error :\n`, error) },
  errorRetryCount: 0,
  revalidateOnFocus: false
}

const renderApp = ({ match }) => {
  const { action, journeyPatternId, lineId, routeId, referentialId, workbenchId } = match.params

  return (
    <SWRConfig value={options}>
      <ShapeEditorMap
        redirectURL={`/workbenches/${workbenchId}/referentials/${referentialId}/lines/${lineId}/routes/${routeId}/journey_patterns`}
        baseURL={`/workbenches/${workbenchId}/referentials/${referentialId}/lines/${lineId}/routes/${routeId}/journey_patterns/${journeyPatternId}`}
        isEdit={action === 'edit'}
      />
    </SWRConfig>
  )
}

export default function App() {
  return (
    <BrowserRouter>
      <Route
        path={'/workbenches/:workbenchId/referentials/:referentialId/lines/:lineId/routes/:routeId/journey_patterns/:journeyPatternId/shapes/:action'}
        render={renderApp}
      />
    </BrowserRouter>
  )
}

import React from 'react'
import { SWRConfig } from 'swr'
import { ShapeContext, defaultValue} from '../shape.context'
import ShapeEditorMap from './ShapeEditorMap'

const options = {
  fetcher: (url) => fetch(url).then(res => res.json())
}

export default function App() {
  return (
    <SWRConfig value={options}>
      <ShapeContext.Provider value={defaultValue}>
        <ShapeEditorMap />
      </ShapeContext.Provider>
    </SWRConfig>
  )
}
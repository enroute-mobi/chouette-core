import React from 'react'
import { SWRConfig } from 'swr'
import ShapeEditorMap from './ShapeEditorMap'

const options = {
  fetcher: url => fetch(url).then(res => res.json()),
  revalidateOnFocus: false
}

export default function App() {
  return (
    <SWRConfig value={options}>
      <ShapeEditorMap />
    </SWRConfig>
  )
}
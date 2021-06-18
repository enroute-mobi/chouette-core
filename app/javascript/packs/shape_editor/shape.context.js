import { createContext } from 'react'

export const defaultValue = {
  baseURL: window.location.pathname.split('/shape_editor')[0],
  lineId: 'line',
  wktOptions: { //  use options to convert feature from EPSG:4326 to EPSG:3857
    dataProjection: 'EPSG:4326',
    featureProjection: 'EPSG:3857'
  }
}

export const ShapeContext = createContext(defaultValue)
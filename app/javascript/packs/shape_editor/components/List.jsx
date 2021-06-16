import React from 'react'
import { convertCoords } from '../shape.reducer'

export default function List({ waypoints }) {
  const list = waypoints.filter(w => w.get('type') == 'waypoint')

  const renderCoordinates = feature => {
    const [lon, lat] = convertCoords(feature)

    return `${lon} - ${lat}`
  }

  return (
    <div className="list">
      <ul>
        {list.map((item, i) => <li key={i}>{item.getProperties().name} | {renderCoordinates(item)}</li>)}
      </ul>
    </div>
  )
}
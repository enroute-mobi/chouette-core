import React from 'react'
import { convertCoords } from './shape.reducer'

function List({ waypoints }) {
  const renderCoordinates = feature => {
    const [lon, lat] = convertCoords(feature)

    return `${lon} - ${lat}`
  }

  return (
    <div className="list">
      <ul>
        {waypoints.map((item, i) => <li key={i}>{item.getProperties().name} | {renderCoordinates(item)}</li>)}
      </ul>
    </div>
  )
}

export default List

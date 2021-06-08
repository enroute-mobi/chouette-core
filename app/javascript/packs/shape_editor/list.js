import React from 'react'

function List({ waypoints }) {
  const renderCoordinates = feature => {
    const [lon, lat] = feature.getGeometry().getCoordinates()

    return `${lon} - ${lat}`
  }

  return (
    <div className="list">
      <ul>
        {waypoints.map((item, i) => <li key={i}>{item.values_.name} | {renderCoordinates(item)}</li>)}
      </ul>
    </div>
  )
}

export default List

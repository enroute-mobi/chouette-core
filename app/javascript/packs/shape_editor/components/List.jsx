import React from 'react'
import { convertCoords } from '../shape.helpers'
import eventEmitter from '../shape.event-emitter'

export default function List({ waypoints }) {
  const onViewPoint = waypoint => {
    eventEmitter.emit('map:zoom-to-waypoint', waypoint)
  }

  const onDeletePoint = waypoint => {
    eventEmitter.emit('map:delete-waypoint-request', waypoint)
  }

  return (
    <table>
      <thead>
        <tr>
          <th>Stop Place</th>
          <th>Latitude</th>
          <th>Longitude</th>
          <th>Actions</th>
        </tr>
      </thead>
      <tbody>
        {waypoints.map((item, i) => {
          const [lon, lat] = convertCoords(item)

          return (
            <tr key={i}>
              <td>{item.get('name')}</td>
              <td>{lon}</td>
              <td>{lat}</td>
              <td>
                <button onClick={() => onViewPoint(item)}>
                  View Point
                </button>
                <button onClick={() => onDeletePoint(item)}>
                  Delete Point
                </button>
              </td>
            </tr>
          )
        })}
      </tbody>
    </table>
  )
}
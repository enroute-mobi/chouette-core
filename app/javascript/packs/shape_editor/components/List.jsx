import React from 'react'
import PropTypes from 'prop-types'
import { get } from 'lodash'
import { getCoord } from '@turf/turf'

import { featureMap } from '../shape.helpers'

const List = ({ onWaypointZoom, onDeleteWaypoint, waypoints = [] }) => (
  <table className="table">
    <thead>
      <tr>
        <th>Stop Place</th>
        <th>Latitude</th>
        <th>Longitude</th>
        <th>Actions</th>
      </tr>
    </thead>
    <tbody>
      {featureMap(waypoints, (item, i) => {
        const [lon, lat] = getCoord(item)

        return (
          <tr key={i}>
            <td>{get(item, ['properties', 'name'], '-')}</td>
            <td>{lon}</td>
            <td>{lat}</td>
            <td>
              <button className="btn btn-default" onClick={() => onWaypointZoom(item)}>
                {I18n.t('shapes.actions.view_waypoint')}
              </button>
              <button className="btn btn-danger" onClick={() => onDeleteWaypoint(item)}>
                {I18n.t('shapes.actions.delete_waypoint')}
              </button>
            </td>
          </tr>
        )
      })}
    </tbody>
  </table>
)

List.propTypes = {
  waypoints: PropTypes.object
}

export default List

import React from 'react'
import PropTypes from 'prop-types'
import { toWgs84 } from '@turf/turf'
import Collection from 'ol/Collection'

const getCoord = item => toWgs84(item.getGeometry().getCoordinates())

const List = ({ onWaypointZoom, onDeleteWaypoint, waypoints }) => (
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
      {waypoints.getArray().map((item, i) => {
        const [lon, lat] = getCoord(item)

        return (
          <tr key={i}>
            <td>{item.get('name') || '-'}</td>
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

List.defaultProps = {
  waypoints: new Collection([])
}

export default List

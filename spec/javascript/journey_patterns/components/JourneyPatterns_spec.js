import React, { Component } from 'react'
import I18n from '../../support/jest-i18n'

import JourneyPatterns from '../../../../app/packs/src/journey_patterns/components/JourneyPatterns'
import renderer from 'react-test-renderer'

describe('stopPointHeader', () => {
  set('features', () => {
    return {}
  })
  set('component', () => {
    let props = {
      status: {
        features: features
      },
      onCheckboxChange: ()=>{},
      onLoadFirstPage: ()=>{},
      onOpenEditModal: ()=>{},
      stopPointsList: [stop_point, same_city_stop_point, other_country_stop_point],
      journeyPatterns: [],
      fetchRouteCosts: () => {}
    }
    let list = renderer.create(
      <JourneyPatterns
        status={props.status}
        journeyPatterns={props.journeyPatterns}
        stopPointsList={props.stopPointsList}
        onCheckboxChange={props.onCheckboxChange}
        onLoadFirstPage={props.onLoadFirstPage}
        onOpenEditModal={props.onOpenEditModal}
        fetchRouteCosts={props.fetchRouteCosts}
      />
    ).toJSON()

    return list
  })

  set('stop_point', () => {
    return {
      name: "Stop point",
      city_name: "City Name",
      zip_code: "12345",
      country_code: "FR",
      country_name: "france",
      object_id: "sp-FR"
    }
  })

  set('same_city_stop_point', () => {
    return {
      name: "Antother stop point",
      city_name: stop_point.city_name,
      zip_code: stop_point.zip_code,
      country_code: stop_point.country_code,
      country_name: stop_point.country_name,
      object_id: stop_point.object_id + "-2"
    }
  })

  set('other_country_stop_point', () => {
    return {
      name: "Antother stop point",
      city_name: "New York",
      zip_code: "232323",
      country_code: "US",
      country_name: "USA",
      object_id: "sp-USA"
    }
  })
  it('should display the city name', () => {
    expect(component).toMatchSnapshot()
  })
  context('with the "long_distance_routes" feature', () => {
    set('features', () => {
      return { long_distance_routes: true }
    })
    it('should display the country name', () => {
      expect(component).toMatchSnapshot()
    })
  })
})

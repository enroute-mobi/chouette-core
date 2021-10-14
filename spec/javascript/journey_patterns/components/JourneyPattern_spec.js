import React, { Component } from 'react'

import I18n from '../../support/jest-i18n'

import JourneyPattern from '../../../../app/packs/src/journey_patterns/components/JourneyPattern'

import renderer from 'react-test-renderer'

describe('the edit button', () => {
  set('policy', () => {
    return {}
  })
  set('features', () => {
    return []
  })
  set('editMode', () => {
    return false
  })
  set('component', () => {
    let props = {
      status: {
        policy: policy,
        features: features
      },
      onCheckboxChange: ()=>{},
      onDeleteJourneyPattern: ()=>{},
      onOpenEditModal: ()=>{},
      journeyPatterns: {},
      value: {
        stop_points: []
      },
      index: 0,
      editMode: editMode,
      fetchRouteCosts: () => {}
    }
    let list = renderer.create(
      <JourneyPattern
        status={props.status}
        journeyPatterns={props.journeyPatterns}
        value={props.value}
        index={props.index}
        onCheckboxChange={props.onCheckboxChange}
        onDeleteJourneyPattern={props.onDeleteJourneyPattern}
        onOpenEditModal={props.onOpenEditModal}
        editMode={props.editMode}
        fetchRouteCosts={props.fetchRouteCosts}
      />
    )

    return list
  })

  it('should display the show link', () => {
    expect(component.toJSON()).toMatchSnapshot()
    expect(component.root.findByProps({"data-target": "#JourneyPatternModal"})._fiber.stateNode.children[0].text).toEqual("Consulter")
  })

  context('in edit mode', () => {
    set('editMode', () => {
      return true
    })

    it('should display the edit link', () => {
      expect(component.toJSON()).toMatchSnapshot()
      expect(component.root.findByProps({"data-target": "#JourneyPatternModal"})._fiber.stateNode.children[0].text).toEqual("Editer")
    })
  })
})

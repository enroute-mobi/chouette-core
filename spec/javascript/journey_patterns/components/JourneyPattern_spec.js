import React, { Component } from 'react'

import I18n from '../../support/jest-i18n'

import renderer from 'react-test-renderer'


beforeEach(() => {
  Object.defineProperty(window, 'location', {
    get() {
      return { pathname: '/referentials/1/lines/1/routes/1' }
    }
  })
})

describe('the edit button', () => {
  set('policy', () => ({}))

  set('features', () => [])

  set('editMode', () => false)

  set('component', () => {
    const props = {
      status: {
        policy,
        features
      },
      onCheckboxChange: () => {},
      onDeleteJourneyPattern: () => {},
      onOpenEditModal: () => {},
      journeyPatterns: {},
      value: {
        stop_points: []
      },
      index: 0,
      editMode,
      fetchRouteCosts: () => {}
    }

    const { default: JourneyPattern } = require('../../../../app/packs/src/journey_patterns/components/JourneyPattern')

    return renderer.create(<JourneyPattern { ...props} />)
  })

  it('should display the show link', () => {
    expect(component.toJSON()).toMatchSnapshot()
    expect(component.root.findByProps({"data-target": "#JourneyPatternModal"})._fiber.stateNode.children[0].text).toEqual("Consulter")
  })

  context('in edit mode', () => {
    set('editMode', () => true)

    it('should display the edit link', () => {
      expect(component.toJSON()).toMatchSnapshot()
      expect(component.root.findByProps({"data-target": "#JourneyPatternModal"})._fiber.stateNode.children[0].text).toEqual("Editer")
    })
  })
})

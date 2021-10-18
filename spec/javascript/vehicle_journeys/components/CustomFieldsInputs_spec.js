import React, { Component } from 'react'
import CustomFieldsInputs from '../../../../app/packs/src/helpers/CustomFieldsInputs'
import renderer from 'react-test-renderer'
require('select2')

describe('CustomFieldsInputs', () => {
  set('values', () => {
    return {}
  })

  set('component', () => {
    let inputs = renderer.create(
      <CustomFieldsInputs
        values={values}
        disabled={false}
        onUpdate={()=>{}}
      />
    ).toJSON()

    return inputs
  })

  it('should match the snapshot', () => {
    expect(component).toMatchSnapshot()
  })

  // context('with fields', () => {
  //   set('values', () => {
  //     return {
  //       foo: {
  //         options: { list_values: ["", "1", "2"] },
  //         field_type: "list",
  //         name: "test"
  //       }
  //     }
  //   })
  //   it('should match the snapshot', () => {
  //     expect(component).toMatchSnapshot()
  //   })
  // })
})

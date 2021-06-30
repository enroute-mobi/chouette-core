import React from 'react'
import Select from 'react-select'
import useSWR from 'swr'

import store from '../shape.store'
import { baseURL } from '../shape.helpers'

export default () => {
  const { data: journeyPatternsOptions } = useSWR(
    `${baseURL}/shape_editor/get_journey_patterns`,
    { initialData: [], revalidateOnMount: true }
  )

  return (
    <Select
      options={journeyPatternsOptions}
      onChange={option => store.setAttributes({ journeyPatternId: option.value })}
    />
  )
}
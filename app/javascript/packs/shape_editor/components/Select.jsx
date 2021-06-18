import React, { useContext }  from 'react'
import Select from 'react-select'
import useSWR from 'swr'

import { ShapeContext } from '../shape.context'

export default props => {
  const { baseURL } = useContext(ShapeContext)

  const { data: journeyPatternsOptions, error } = useSWR(`${baseURL}/shape_editor/get_journey_patterns`)
  return (
    <Select
      options={journeyPatternsOptions || []}
      onChange={option => props.setJourneyPatternId(option.value)}
    />
  )
}
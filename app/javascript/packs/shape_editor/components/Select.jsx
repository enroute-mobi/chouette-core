import React, { useContext }  from 'react'
import Select from 'react-select'
import useSWR from 'swr'

import { ShapeContext } from '../shape.context'

export default ({ setJourneyPatternId }) => {
  const { baseURL } = useContext(ShapeContext)

  const { data: journeyPatternsOptions } = useSWR(
    `${baseURL}/shape_editor/get_journey_patterns`,
    { initialData: [], revalidateOnMount: true }
  )

  return (
    <Select
      options={journeyPatternsOptions}
      onChange={option => setJourneyPatternId(option.value)}
    />
  )
}
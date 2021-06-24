import React from 'react'
import Select from 'react-select'
import useSWR from 'swr'
import { pick } from 'lodash'

import store from '../shape.store'
import { useStore } from '../../../helpers/hooks'

export default () => {
  const [{ baseURL, setAttributes }] = useStore(
    store,
    state => pick(state, ['baseURL', 'setAttributes'])
  )

  const { data: journeyPatternsOptions } = useSWR(
    `${baseURL}/shape_editor/get_journey_patterns`,
    { initialData: [], revalidateOnMount: true }
  )

  return (
    <Select
      options={journeyPatternsOptions}
      onChange={option => setAttributes({ journeyPatternId: option.value })}
    />
  )
}
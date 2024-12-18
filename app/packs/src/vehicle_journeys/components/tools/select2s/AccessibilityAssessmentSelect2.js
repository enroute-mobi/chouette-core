import React from 'react'
import { Async as Select } from 'react-select'
import { Path } from 'path-parser'

const params = new Path('/workbenches/:workbenchId/referentials/:referentialId/lines/:lineId/routes/:routeId').partialTest(location.pathname)
const accessibility_assessmentsPathParams = new Path('/workbenches/:workbenchId/shape_referential/accessibility_assessments').partialTest(window.accessibilityAssessmentsPath || '') // Doing for to let specs pass (could not find a wat to mock window values properly)

const path = `/workbenches/${accessibility_assessmentsPathParams?.workbenchId}/shape_referential/accessibility_assessments/autocomplete`

const AccessibilityAssessmentSelect2 = ({ accessibility_assessment, editMode, editModal, onSelect2AccessibilityAssessment, onUnselect2AccessibilityAssessment }) => (
  <Select
    cacheOptions
    isClearable
    defaultOptions
    defaultValue={accessibility_assessment?.id ? { id: accessibility_assessment.id, text: accessibility_assessment.name } : undefined }
    getOptionLabel={({ text }) => text}
    getOptionValue={({ id }) => id}
    loadOptions={async inputValue => {
      const response = await fetch(`${path}.json?${new URLSearchParams({ q: inputValue }).toString()}`)
      const accessibility_assessments = await response.json()

      return accessibility_assessments
    }}
    isDisabled={!editMode && editModal}
    placeholder={I18n.t('vehicle_journeys.vehicle_journeys_matrix.affect_accessibility_assessment')}
    onChange={(accessibility_assessment, meta) => {
      switch(meta.action) {
        case 'select-option':
          onSelect2AccessibilityAssessment({ id: accessibility_assessment.id, name: accessibility_assessment.text })
          break
        case 'deselect-option':
        case 'clear':
          onUnselect2AccessibilityAssessment()
          break
      }
    }}
    styles={{
      control: (provided) => ({
        ...provided,
        minHeight: '51px',
        height: '51px'
      }),
      menu: base => ({ ...base, zIndex: 2000 })
    }}
  />
)

export default AccessibilityAssessmentSelect2

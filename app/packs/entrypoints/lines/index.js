const transportModeCheckboxes = $('.js-transport-mode-checkboxes :checkbox')
const submodeCheckboxes = $('.js-transport-submode-checkboxes :checkbox')

const updateSubmodeOptions = (event) => {
  const numberOfModes = transportModeCheckboxes.length
  const selectedModes = $('.js-transport-mode-checkboxes :checked').map((i, mode) => mode.dataset.transportMode)

  submodeCheckboxes.attr('disabled', true)

  if (selectedModes.length == 0 || selectedModes.length == numberOfModes) {
    submodeCheckboxes.attr('disabled', false)
  } else {
    const submodeOptions = Array.from(selectedModes).reduce((acc, mode) => {
      const options = $('.js-transport-submode-checkboxes').data('transport_submodes')[mode] || []
      return acc.concat(options)
    }, [])

    submodeOptions.forEach( ([_, value]) => {
      value && $(`[data-transport-submode=${value}]`).attr('disabled', false)
    })
  }
}

transportModeCheckboxes.change(updateSubmodeOptions)

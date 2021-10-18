export default class StopAreaFormHelper {
  constructor() {
    this.handleKindChange('commercial', false)
    this.handleKindChange('non_commercial', true)

    this.checkbox = $('#stop_areais_referent')
    this.referentInput = $('#referent_input')
    this.switchReferentInput = this.switchReferentInput.bind(this)

    this.switchReferentInput()
    this.checkbox.on('change', this.switchReferentInput)
  }

  handleKindChange(kind, bool) {
    document.getElementById(`stop_area_kind_${kind}`).addEventListener('change', () => {
      document.getElementById('stop_area_parent_id').disabled = bool
    })
  }

  switchReferentInput() {
    if (this.checkbox.prop("checked")) {
      $('#stop_area_referent_id').val(null).trigger('change')
      this.referentInput.hide()
    } else {
      this.referentInput.show()
    }
  }
}

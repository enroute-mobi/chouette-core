import TomSelect from 'tom-select'

new TomSelect('#publication_setup_destinations_attributes_0_recipients', {
  create: true,
  createOnBlur: true,
  persist: false,
  placeholder: I18n.t('simple_form.custom_inputs.tags.placeholder'),
  createFilter: function(input) {
    input = input.toLowerCase()
    const isInOptions = input.toLowerCase() in this.options
    const isEmail = Boolean(input.match(/.+\@.+\..+/))
		return !isInOptions && isEmail
	},
  render: {
    option_create: (data, escape) => (
      `<div class="create">${I18n.t('actions.add')} <strong>${escape(data.input)}</strong>&hellip;</div>`
    ),
    no_results: () => null
  }
})
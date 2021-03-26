export default class AutoComplete {
  constructor($select, options = {}) {
    this.$select = $($select)
    this.domainName = window.location.origin
    const { ajax, ...restOptions } = options
    this.options = restOptions
    this.ajaxOptions = ajax
  }

  init() {
    this.$select.select2({
      ajax: {
        cache: false,
        url: () => this.domainName + this.$select.data('ajaxPath'),
        dataType: 'json',
        delay: 250,
        data: params => ({ q: params.term }),
        processResults: data => ({ results: data }),
        ...this.ajaxOptions
      },
      theme: 'bootstrap',
      width: '100%',
      language: I18n.locale,
      minimumInputLength: 1,
      templateResult: item => item.text,
      templateSelection: item => item.text,
      ...this.options
    })
  }
}
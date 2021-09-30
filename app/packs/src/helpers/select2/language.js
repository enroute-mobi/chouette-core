export default {
  errorLoading: () => I18n.t('select2.error_loading'),
  inputTooLong: (e) => I18n.t('select2.input_too_long', { count: e.input.length - e.maximum}),
  inputTooShort: (e) => I18n.t('select2.input_too_short', { count: e.minimum - e.input.length }),
  loadingMore: () => I18n.t('select2.loading_more'),
  maximumSelected: (e) => I18n.t('select2.maximum_selected', {count: e.maximum}),
  noResults: () => I18n.t('select2.no_results'),
  searching: () => I18n.t('select2.searching')
}
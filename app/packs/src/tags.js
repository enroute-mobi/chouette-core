/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
const bind_select2 = function(el, cfg) {
  if (cfg == null) { cfg = {}; }
  const target = $(el);

  const default_cfg = {
    theme: 'bootstrap',
    language: I18n.locale,
    placeholder: target.data('select2ed-placeholder'),
    tags: true,
    width: '100%',
    allowClear: true
  };

  return target.select2($.extend({}, default_cfg, cfg));
};

$(() => $('select.form-control.tags').each(function() {
  return bind_select2(this);
}));

if (typeof module !== 'undefined' && module !== null) {
  module.exports = bind_select2;
}

bind_select2 = (el, cfg = {}) ->
  target = $(el)

  default_cfg =
    theme: 'bootstrap'
    language: I18n.locale
    placeholder: target.data('select2ed-placeholder')
    tags: true
    width: '100%'
    allowClear: true

  target.select2 $.extend({}, default_cfg, cfg)

$ ->
  $('select.form-control.tags').each ->
    bind_select2(this)

module?.exports = bind_select2

bind_select2 = (el, cfg = {}) ->
  target = $(el)
  default_cfg =
    theme: 'bootstrap'
    language: 'fr'
    placeholder: target.data('select2ed-placeholder')
    allowClear: !!target.data('select2ed-allow-clear')

  target.select2 $.extend({}, default_cfg, cfg)

bind_select2_ajax = (el, cfg = {}) ->
  _this = $(el)
  cfg =
    ajax:
      data: (params) ->
        if _this.data('term')
          { q: "#{_this.data('term')}": params.term }
        else
          { q: params.term }
      url: _this.data('url'),
      dataType: 'json',
      delay: 125,
      processResults: (data, params) -> results: data
    templateResult: (item) ->
      item.text
    templateSelection: (item) ->
      item.text
    escapeMarkup: (markup) ->
      markup

  initValue = _this.data('initvalue')
  if initValue && initValue.id && initValue.text
    cfg["initSelection"] = (item, callback) -> callback(_this.data('initvalue'))

  bind_select2(el, cfg)

@select_2 = ->
  $("[data-select2ed='true']").each ->
    bind_select2(this)

  $("[data-select2-ajax='true']").each ->
    bind_select2_ajax(this)

  $('select.form-control.tags').each ->
    bind_select2(this, {tags: true})

$ ->
  select_2()

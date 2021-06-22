bind_select2 = (el, cfg = {}) ->
  target = $(el)
  decorate_option_with_flag = (item, text)->
    $("<span><span class='flag-icon flag-icon-#{$(item.element).attr('id').toLowerCase()} mr-xs'></span>#{text}</span>")

  default_cfg =
    theme: 'bootstrap'
    language: I18n.locale
    placeholder: target.data('select2ed-placeholder')
    allowClear: !!target.data('select2ed-allow-clear')
    searchingText: I18n.t('actions.searching_term')
    noResultsText: I18n.t('actions.no_result_text')
    templateResult: (item) ->
      text = if item.text.length > 50 then item.text.substring(0, 47) + '...' else item.text
      if item.element && target.hasClass('country-select')
        decorate_option_with_flag(item, text)
      else
        text
    templateSelection: (item) ->
      text = if item.text.length > 50 then item.text.substring(0, 47) + '...' else item.text
      if item.element && target.hasClass('country-select')
        decorate_option_with_flag(item, text)
      else
        text

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

$ ->
  $("[data-select2ed='true']").each ->
    bind_select2(this)

  $("[data-select2-ajax='true']").each ->
    bind_select2_ajax(this)

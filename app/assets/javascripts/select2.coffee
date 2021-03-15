bind_select2 = (el, cfg = {}) ->
  console.log('bind', el)
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

@select_2 = ->
  $("[data-select2ed='true']").each ->
    bind_select2(this)

  $("[data-select2-ajax='true']").each ->
    bind_select2_ajax(this)

$ ->
  select_2()
  $('select.autocomplete-async-input').each (i, e)->
    vals = $(e).data().values
    select2ed = $(e).select2
      theme: 'bootstrap',
      width: '100%',
      allowClear: true,
      placeholder: $(e).data().placeholder,
      ajax:
        url: $(e).data().url,
        dataType: 'json',
        delay: '500',
        processResults: (data) ->
          {
            results: data
          }
        data:  (params) ->
          {
            q: params.term
          }

      templateResult: (props) -> $('<span>').html(props.text)
      templateSelection:  (props) -> $('<span>').html(props.text)

    select2ed.prop("disabled", true)
    loadNext = ->
      if vals == null || vals == "" || vals.length == 0
        select2ed.prop("disabled", false)
        return
      val = vals.pop()
      if val == null || val == ""
        select2ed.prop("disabled", false)
        return
      $.ajax
        type: 'GET',
        url: $(e).data().loadUrl + "/" + val + ".json"
      .then (data)->
        option = new Option(data.text, data.id, true, true);
        select2ed.append(option).trigger('change');
        select2ed.trigger
          type: 'select2:select',
          params: {
              data: data
          }
        loadNext()
    loadNext()

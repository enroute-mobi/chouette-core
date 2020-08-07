$ ->
  $('#export_referential_id').change ->
    $('#export_line_code').empty()
    domain_name = $('#export_line_code').attr("data-domain-name")
    $('#export_line_code').attr("data-ajax--url", domain_name + "/referentials/" + this.value + "/autocomplete/lines")

  # initialize autocomplete select lines
  $('#export_line_code').select2
    ajax:
      cache: false,
      url:  (params) ->
        $('#export_line_code').attr("data-ajax--url")
      dataType: 'json',
      delay: 250,
      data: (params) ->
        {
          q: params.term
        }
      processResults: (data, params) ->
        # parse the results into the format expected by Select2
        # since we are using custom formatting functions we do not need to
        # alter the remote JSON data, except to indicate that infinite
        # scrolling can be used
        results: data
    theme: 'bootstrap',
    width: '100%',
    language: I18n.locale,
    minimumInputLength: 1,
    templateResult: (item) ->
      item.text
    templateSelection: (item) ->
      item.text

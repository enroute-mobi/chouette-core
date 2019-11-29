class TransportModesEditor
  constructor: (@table, @input)->
    @values = JSON.parse @input.val()
    @updateTable()
    @filter = @table.find('select[name=mode]')
    @table.find('input[type=checkbox]').change (e)=>
      @updateValues($(e.currentTarget))

    # Click on row to check the embeded checkbox
    @table.find('tbody td:not(.actions)').click (e)=>
      $(e.currentTarget).parent().find('input').click()

    @filter.change (e)=>
      @applyFilter()

  updateTable: ->
    @table.find('input[type=checkbox]').each (i, el)->
      $(el).attr('checked', false)

    @table.find('tr').each (i, el)->
      $(el).css('background-color', '')

    for mode, submodes of @values
      for submode in submodes
        @table.find("input[type=checkbox][name='#{mode}[_#{submode}]']").attr('checked', true)
        @table.find("tr.#{mode}.#{submode}").css('background-color', 'rgba(72, 177, 0, 0.3)')

      @table.find("input[type=checkbox][name='#{mode}[undefined]']").attr('disabled', submodes.length > 1)
      @table.find("tr.#{mode}[data-submode=undefined]").toggleClass('disabled', submodes.length > 1)

  updateValues: (checkbox)=>
    mode = checkbox.attr('data-mode')
    submode = checkbox.attr('data-submode')
    if checkbox.is(':checked')
      @values[mode] ?= []
      @values[mode].push submode if @values[mode].indexOf(submode) < 0
      @values[mode].push('undefined') if @values[mode].indexOf('undefined') < 0
    else
      @values[mode].splice(@values[mode].indexOf(submode), 1)

    @input.val JSON.stringify(@values)
    @updateTable()

  applyFilter: =>
    @table.find('tbody tr').show()
    return if @filter.val() == 'all'

    @table.find("tbody tr:not(.#{@filter.val()})").hide()


export default TransportModesEditor

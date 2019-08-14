class TransportModesEditor
  constructor: (@table, @input)->
    @values = JSON.parse @input.val()
    @updateTable()
    @filter = @table.find('select[name=mode]')
    @table.find('input[type=checkbox]').change (e)=>
      @updateValues($(e.currentTarget))
    @table.find('tbody tr').click (e)=>
      $(e.currentTarget).find('input').click()

    @filter.change (e)=>
      @applyFilter()


  updateTable: ->
    @table.find('input[type=checkbox]').each (i, e)->
      $(e).attr('checked', false)

    for mode, submodes of @values
      console.log({mode, submodes})
      for submode in submodes
        console.log("input[type=checkbox][name='#{mode}[#{submode}]']")
        @table.find("input[type=checkbox][name='#{mode}[#{submode}]']").attr('checked', true)

  updateValues: (checkbox)=>
    mode = checkbox.attr('data-mode')
    submode = checkbox.attr('data-submode')
    if checkbox.is(':checked')
      @values[mode] ?= []
      @values[mode].push submode
    else
      delete @values[mode][submode]

    @input.val JSON.stringify(@values)

  applyFilter: =>
    @table.find('tbody tr').show()
    return if @filter.val() == 'all'

    console.log("tbody tr:not(.#{@filter.val()})")
    @table.find("tbody tr:not(.#{@filter.val()})").hide()


export default TransportModesEditor

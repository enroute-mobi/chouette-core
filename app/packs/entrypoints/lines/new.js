import '../../src/helpers/polyfills'

import MasterSlave from "../../src/helpers/master_slave"

new MasterSlave("form")

const toggleLineDates = function(){
  var disabled = ! $('[name="line[activated]"').is(':checked')
  $('[name="line[active_from]"').attr('disabled', disabled)
  $('[name="line[active_until]"').attr('disabled', disabled)
}

$('[name="line[activated]"').change(toggleLineDates)
toggleLineDates()

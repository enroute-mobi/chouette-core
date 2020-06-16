import bind_select2 from '../../assets/javascripts/tags'

class MasterSlave
  constructor: (@selector)->
    $(@selector).on 'cocoon:after-insert', =>
      @initBehaviours()

    @initBehaviours()


  initBehaviours: ->
    $(@selector).find('[data-master]').each (i, slave)->
      $slave = $(slave)
      master = $($slave.data().master)
      if $slave.find('[data-master]').length == 0
        $slave.find("input:disabled, select:disabled, textarea:disabled").attr "data-slave-force-disabled", "true"
      toggle = (disableInputs=true)->
        val = master.filter(":checked").val() if master.filter("[type=radio]").length > 0
        val = master.prop('checked') if master.hasClass('onoffswitch-checkbox')
        val ||= master.val()
        selected = "#{val}" == "#{$slave.data().value}"
        $slave.toggle selected
        $slave.toggleClass "active", selected
        if disableInputs
          disabled = !selected
          disabled = disabled || $slave.parents("[data-master]:not(.active)").length > 0
          $slave.find("input, select, textarea").filter(":not([data-slave-force-disabled])").attr "disabled", disabled
        if selected
          $("[data-select2ed='true']").select2()
          $('select.form-control.tags').each ->
            bind_select2(this)
      master.change toggle
      toggle($slave.find('[data-master]').length == 0)

export default MasterSlave

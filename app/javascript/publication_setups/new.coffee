initPublicationSetupButtons = (container)->
  $(container).find("input[type=checkbox][name*=destroy]").each (i, el)->
    $el = $(el)
    $group = $($el.parents('.form-group')[0])
    $group.hide()

    $outer_wrapper = $('<div class="form-group"></div>')
    $wrapper = $('<div class="col-md-12"></div>')
    $wrapper.appendTo $outer_wrapper
    $outer_wrapper.insertAfter $group

    $btDelete = $("<a href='#' class='pull-right btn btn-danger'><i class='fa fa-trash'></i><span>#{I18n.t('actions.destroy')}</span></a>")
    $btDelete.appendTo $wrapper

    $btDelete.click (e)->
      $el.click()
      e.preventDefault()
      $btDelete.hide()
      $btRestore.show()
      false

    $btRestore = $("<a href='#' class='pull-right btn btn-info'><i class='fa fa-sync'></i><span>#{I18n.t('actions.restore')}</span></a>")
    $btRestore.appendTo $wrapper
    $btRestore.hide()

    $btRestore.click (e)->
      $el.click()
      e.preventDefault()
      $btRestore.hide()
      $btDelete.show()
      false

  $(container).find("input[name*=destroy]").change (e)->
    $(e.target).parents('.destination').find('.fields').toggleClass('hidden-fields', e.target.checked)
    $(e.target).parents('.destination').find('input[name*=name]').attr('readonly', e.target.checked)


$(".destination").each (i, el)->
  initPublicationSetupButtons(el)

$('form').on 'cocoon:after-insert', (e, insertedItem)->
  initPublicationSetupButtons(insertedItem)

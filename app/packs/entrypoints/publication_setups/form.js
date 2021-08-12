const initPublicationSetupButtons = container => {
  $(container).find("input[type=checkbox][name*=destroy]").each((i, el) => {
    const $el = $(el)
    const $group = $($el.parents('.form-group')[0])
    $group.hide()

    const $outer_wrapper = $('<div class="form-group"></div>')
    const $wrapper = $('<div class="col-md-12"></div>')
    $wrapper.appendTo($outer_wrapper)
    $outer_wrapper.insertAfter($group)

    const $btDelete = $(`<a href='#' class='pull-right btn btn-danger'><i class='fa fa-trash'></i><span>${I18n.t('actions.destroy')}</span></a>`)
    $btDelete.appendTo($wrapper)

    $btDelete.on('click', e => {
      $el.trigger('click')
      e.preventDefault()
      $btDelete.hide()
      $btRestore.show()
      return false
    })

    const $btRestore = $(`<a href='#' class='pull-right btn btn-info'><i class='fa fa-sync'></i><span>${I18n.t('actions.restore')}</span></a>`)
    $btRestore.appendTo($wrapper)
    $btRestore.hide()

    $btRestore.on('click', e => {
      $el.trigger('click')
      e.preventDefault()
      $btRestore.hide()
      $btDelete.show()
      return false
    })
  })

  $(container).find("input[name*=destroy]").on('change', e => {
    $(e.target).parents('.destination').find('.fields').toggleClass('hidden-fields', e.target.checked)
    $(e.target).parents('.destination').find('input[name*=name]').attr('readonly', e.target.checked)
  })
}

$(".destination").each((i, el) => {
  initPublicationSetupButtons(el)
})

$('form').on('cocoon:after-insert', (e, insertedItem) => {
  initPublicationSetupButtons(insertedItem)
})
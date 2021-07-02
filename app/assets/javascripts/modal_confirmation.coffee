showConfirmModal = (link) ->
  message = link.data('confirm')
  html = """<div class="modal fade" id="confirmationDialog" tabindex="1" role="dialog">
    <div class="modal-container">
      <div class="modal-dialog">
        <div class="modal-content">
          <div class="modal-header">
            <h4 class="modal-title"> #{I18n.t('warning')} </h4>
          </div>
          <div class="modal-body">
            <p>#{message}</p>
          </div>
          <div class="modal-footer">
            <a data-dismiss="modal" class="btn btn-cancel">#{I18n.t('no')}</a>
            <a data-dismiss="modal" class="btn btn-default" data-method="#{link.data().method}" href="#{link.attr('href')}">#{I18n.t('yes')}</a>
          </div>
        </div>
      </div>
    </div>
  </div>"""
  $(html).modal()

$ ->
  $.rails.allowAction = (link) ->
    return true if !link.attr('data-confirm') || link.attr('href') == '#'
    showConfirmModal link
    false

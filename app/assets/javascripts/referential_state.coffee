window.client ||= new Faye.Client('/faye')

class ReferentialStateUpdater
  constructor: (@channel)->
    console.log "subscribing to #{@channel}"
    @currentState = $('meta[name=referential_state]').attr('content')
    console.log "current state is #{@currentState}"

    window.client.subscribe @channel, (payload) =>
      @receivedState payload.state

  receivedState: (newState)->
    if newState != @currentState
      @updateState newState

  updateState: (newState)->
    console.log "Referential state changed: #{@currentState} -> #{newState}"
    @currentState = newState
    @showFlashMessage()

  showFlashMessage: ->
    $(".state-update.alert").remove()
    message = $('<div></div>')
    message.addClass "alert"
    message.addClass "state-update"
    if @currentState == "active"
      message.addClass "alert-success"
    else
      message.addClass "alert-danger"

    icon = $('<span class="fa fa-info-circle"></span>')
    message.text I18n.t("referentials.states.changed.#{@currentState}")
    icon.prependTo message
    message.insertBefore $(".page_header")

$ ->
  _location = document.location.pathname.split("/")
  if _location[1] == "referentials"
    new ReferentialStateUpdater "/referentials/#{_location[2]}"

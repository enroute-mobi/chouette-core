window.client ||= new Faye.Client('/faye')

class window.NotificationCenter
  constructor: (@channel, @receiver)->
    @lastSeen = @getCookie
    window.client.subscribe @channel, (payload) =>
      @receivedNotification payload

  cookieKey: ->
     "notifications_#{@channel.replace(/\//g, '_')}_last_seen"

  receivedNotification: (payload)=>
    @setLastSeen payload.created_at
    @receiver.receivedNotification payload

  setLastSeen: (timestamp)=>
    @lastSeen = timestamp
    @setCookie "notifications_#{@channel}_last_seen", @lastSeen

  setCookie: (value, days) ->
    name = @cookieKey()
    if days
      date = new Date()
      date.setTime date.getTime() + (days * 24 * 60 * 60 * 1000)
      expires = "; expires=" + date.toGMTString()
    else
      expires = ""
    document.cookie = name + "=" + value + expires + "; path=/"

  getCookie: () ->
    name = @cookieKey()
    nameEQ = name + "="
    ca = document.cookie.split(";")
    i = 0

    while i < ca.length
      c = ca[i]
      c = c.substring(1, c.length)  while c.charAt(0) is " "
      return c.substring(nameEQ.length, c.length)  if c.indexOf(nameEQ) is 0
      i++
    null

  deleteCookie: (name) ->
    setCookie name, "", -1

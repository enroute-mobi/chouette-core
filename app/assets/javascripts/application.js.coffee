# This is a manifest file that'll be compiled into including all the files listed below.
# Add new JavaScript/Coffee code in separate files in this directory and they'll automatically
# be included in the compiled file accessible from http://example.com/assets/application.js
# It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
# the compiled file.
#
#= require jquery
#= require jquery_ujs
#= require modernizr
#= require cocoon
#= require ./OpenLayers/ol.js
#= require bootstrap-sass-official
#= require bootstrap/clockpicker
#= require select2-full
#= require select2_locale_fr
#= require jquery-tokeninput
#= require tagmanager
#= require footable
#= require footable/footable.filter
#= require footable/footable.paginate
#= require footable/footable.sort
#= require_directory ./plugins
#= require_directory .
# require('whatwg-fetch')
# require('babel-polyfill')
#= require "i18n"
#= require "i18n/extended"
#= require "i18n/translations"
#= require jquery-ui/widgets/draggable
#= require jquery-ui/widgets/droppable
#= require jquery-ui/widgets/sortable
#= require ellipsis

$ ->
  $('a[disabled=disabled]').click (event)->
    event.preventDefault(); # Prevent link from following its href

  $('.custom_field_attachment_wrapper input[type=file]').change (e)->
    if e.target.value
      $(e.target).parents(".custom_field_attachment_wrapper").find('.delete-wrapper').removeClass('hidden')
      $(e.target).parents(".custom_field_attachment_wrapper").find('.btn label').html(e.target.value.split(/[\\/]/).pop())
      $(e.target).parents(".custom_field_attachment_wrapper").find('.delete-wrapper input[type=checkbox]')[0].checked = false
    else
      $(e.target).parents(".custom_field_attachment_wrapper").find('.delete-wrapper').addClass('hidden')
      $(e.target).parents(".custom_field_attachment_wrapper").find('.btn label').html(I18n.t("actions.select"))

  $('.custom_field_attachment_wrapper .delete-wrapper input').change (e)->
    if $(e.target).is(":checked")
      $(e.target).parents(".custom_field_attachment_wrapper").find('.btn label').html(I18n.t("actions.select"))
      $(e.target).parents(".delete-wrapper").addClass('hidden')

  $('.page-title h1').ellipsis()

  cooldown = null
  $(window).resize ->
    clearTimeout(cooldown) if cooldown
    cooldown = setTimeout ->
      $('.page-title h1').ellipsis()
      cooldown = null
    , 200

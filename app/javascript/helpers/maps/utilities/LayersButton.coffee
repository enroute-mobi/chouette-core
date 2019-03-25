LayersButton = (options) ->
  menu = options.menu

  toggleMenu = (e)=>
    $(menu.element).toggleClass 'hidden'
    button.innerHTML = if button.innerHTML == "+" then "-" else "+"

  button = document.createElement("button")
  button.innerHTML = "+"
  button.addEventListener('click', toggleMenu, false)
  button.addEventListener('touchstart', toggleMenu, false)
  button.className = "ol-routes-layers-button"

  element = document.createElement('div');
  element.className = 'ol-control ol-routes-layers-button-wrapper';

  element.appendChild(button)

  ol.control.Control.call(this, {
    element
    target: options.target
  })

ol.inherits LayersButton, ol.control.Control

export default LayersButton

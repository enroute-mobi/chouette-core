export default function LayersButton(options) {
  const { menu, target, resourceName } = options

  const toggleMenu = e => {
    $(menu.element).toggleClass('hidden')
    return button.innerHTML = button.innerHTML === '+' ? '-' : '+'
  }

  let button = document.createElement('button')
  button.innerHTML = '+'
  button.addEventListener('click', toggleMenu, false)
  button.addEventListener('touchstart', toggleMenu, false)
  button.className = `ol-${resourceName}-layers-button`

  let element = document.createElement('div')
  element.className = `ol-control ol-${resourceName}-layers-button-wrapper`

  element.appendChild(button)

  return ol.control.Control.call(this, {
    element,
    target
  })
}

ol.inherits(LayersButton, ol.control.Control)
import React from 'react'

import { render } from 'react-dom'
import { Provider } from 'react-redux'
import { createStore } from 'redux'

import applyMiddleware from '../../src/helpers/middlewares'
import reducers from '../../src/routes/reducers'
import App from '../../src/routes/containers/App'

const store = createStore(reducers, {}, applyMiddleware())

document.addEventListener("DOMContentLoaded", () => {
  if (document.getElementById("route")) {
    render(
      <Provider store={store}>
        <App />
      </Provider>,
      document.getElementById('route')
    )
  }
})
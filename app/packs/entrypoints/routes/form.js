import '../../src/helpers/polyfills'

import React from 'react'
import PropTypes from 'prop-types'

import { render } from 'react-dom'
import { Provider } from 'react-redux'
import { createStore } from 'redux'

import applyMiddleware from '../../src/helpers/middlewares'
import reducers from '../../src/routes/reducers'
import App from '../../src/routes/containers/App'

let store = null

if(Object.assign){
  store = createStore(
   reducers,
   {},
   applyMiddleware()
 )
}
else{
  // IE
  store = createStore(
   reducers,
   {},
   applyMiddleware()
 )
}


render(
  <Provider store={store}>
    <App />
  </Provider>,
  document.getElementById('route')
)

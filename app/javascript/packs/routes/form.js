import '../../helpers/polyfills'

import React from 'react'
import PropTypes from 'prop-types'

import { render } from 'react-dom'
import { Provider } from 'react-redux'
import { createStore } from 'redux'

import applyMiddleware from '../../helpers/middlewares'
import reducers from '../../routes/reducers'
import App from '../../routes/containers/App'
  
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

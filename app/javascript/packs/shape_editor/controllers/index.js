/*
  React Controller (state: object, dispatch: function) => void

  Based on the current state, a React controller is a custom hook that is responsible for :
   - affecting the UI
   - data fetching
*/

const useCombineControllers = (state, dispatch) => (...controllers) => {
  controllers.forEach(controller => {
    controller(state, dispatch)
  })
}

export default useCombineControllers
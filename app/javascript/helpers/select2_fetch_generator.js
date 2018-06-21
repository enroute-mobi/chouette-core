export default function select2Fecth(url, input, callback) {
  return run(fetchWithTimeout(url, input, callback))
}

// Generator Function

function* fetchWithTimeout(url, input, callback, component) {
  try {
    let response = yield timeoutPromise(url)
    let object = yield response.json()
    return object
  } catch (error) {
    console.error("Error in Fetch : \n", error)
  }
}

// Generator Handler

function run(generator) {

  return new Promise(resolve => {
    function badResultStatus(result) {
      if (result == undefined || !result.hasOwnProperty('status') || !result.hasOwnProperty('ok')) return false
      return result.status == 500 || !result.ok
    }

    function onResult(lastPromiseResult) {
      if (badResultStatus(lastPromiseResult)) {
        generator.throw(new ResponseExcetion(lastPromiseResult))
        return
      }

      let { value, done } = generator.next(lastPromiseResult)

      if (!done) {
        value.then(onResult, error => {
          generator.throw(error)
          return
        })
      } else {
        resolve(value)
      }
    }
    onResult()
  })
}

// Helper function

function timeoutPromise(url) {
  function fetchObjects(url) {
    return fetch(url, {
      credentials: 'same-origin',
      contentType: 'application/json; charset=utf-8',
      Accept: 'application/json',
      headers: {
        'X-CSRF-Token': $('meta[name="csrf-token"]').attr('content')
      }
    })
  }
  return new Promise(function (resolve, reject) {
    resolve(fetchObjects(url))
    setTimeout(reject(new TimeoutExcetion(500)), 500)
  })
}

// Exceptions

function ResponseExcetion({ status, statusText, url }) {
  this.name = 'ResponseExcetion'
  this.status = status
  this.message = statusText
  this.url = url
}

function TimeoutExcetion(delay) {
  this.name = 'TimeoutExcetion'
  this.delay = delay
}
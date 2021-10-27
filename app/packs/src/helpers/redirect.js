const handleRedirect = callback => response => {
  for (const [name, value] of response.headers.entries()) {
    if (name === 'location') {
      const status = response.ok ? 'notice' : 'error'
      callback(status)

      location.assign(value)
    }
  }
}

export default handleRedirect
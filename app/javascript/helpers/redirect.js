const handleRedirect = callback => response => {
  for (const [name, value] of response.headers.entries()) {
    if (name === 'location') {
      callback()

      location.assign(value)
    }
  }
}

export default handleRedirect
const images = require.context('../../images', true)

export default (name) => images(name, true)

const { webpackConfig, merge } = require('@rails/webpacker')
const loaders = require('./loaders')

const extentionsConfig = {
  resolve: {
    extensions: ['.js', '.jsx', '.coffee', '.css', '.sass', '.svg', '.png', '.jpg']
  }
}


module.exports = merge(webpackConfig, loaders, extentionsConfig)

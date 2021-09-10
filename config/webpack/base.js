const { webpackConfig, merge } = require('@rails/webpacker')
const loaders = require('./loaders')

const extentionsConfig = {
  resolve: {
    extensions: ['.js', '.jsx', '.coffee', '.css', '.sass', '.scss', '.svg', '.png', '.jpg', '.woff', '.woff2', '.eot', '.ttf']
  }
}


module.exports = merge(webpackConfig, loaders, extentionsConfig)

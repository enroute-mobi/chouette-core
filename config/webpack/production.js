const environment = require('./environment')
const webpack = require('webpack')
const UglifyJsPlugin = require('uglify-js')

let plugin = new webpack.EnvironmentPlugin({
	NODE_ENV: 'production'
})

environment.plugins.append('EnvironmentPlugin', plugin)
environment.plugins.append(
  'UglifyJs',
  new webpack.optimize.UglifyJsPlugin({
    compress: {
      warnings: false
    }
  })
)

module.exports = environment.toWebpackConfig()

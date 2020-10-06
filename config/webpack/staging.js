const environment = require('./environment')
const webpack = require('webpack')
const UglifyJSPlugin = require('uglify-js')

optimization: {
  minimizer: [
    new UglifyJSPlugin({
			compress: {
	      warnings: false
	    }
    })
  ]
}

module.exports = environment.toWebpackConfig()

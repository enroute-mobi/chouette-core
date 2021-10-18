const { environment } = require('@rails/webpacker')
const coffee =  require('./loaders/coffee')
const CleanWebpackPlugin = require('clean-webpack-plugin')

let pathsToClean = [
  'public/packs'
];

let cleanOptions = {
  root: __dirname + '/../../',
  verbose: true,
  dry: false
};

environment.plugins.append(
  'CleanWebpack',
  new CleanWebpackPlugin(pathsToClean, cleanOptions)
)

environment.loaders.append('coffee', coffee)
module.exports = environment

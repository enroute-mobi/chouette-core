const { environment } = require('@rails/webpacker')
const CleanWebpackPlugin = require('clean-webpack-plugin')

let pathsToClean = [
  'public/packs'
];

// the clean options to use
let cleanOptions = {
  root: __dirname + '/../../',
  verbose: true,
  dry: false
};


environment.plugins.set(
  'CleanWebpack',
  new CleanWebpackPlugin(pathsToClean, cleanOptions)
)

// environment.plugins.set('Provide', new webpack.ProvidePlugin({
//     $: 'jquery',
//     jQuery: 'jquery',
//     jquery: 'jquery'
//   })
// )

// const config = environment.toWebpackConfig()

// config.resolve.alias = {
//   jquery: "jquery/src/jquery",
// }

module.exports = environment

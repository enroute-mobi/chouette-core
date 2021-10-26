const globImporter = require('node-sass-glob-importer');
const Dotenv = require('dotenv-webpack');

module.exports = {
  module: {
    rules: [
      {
        test: /\.scss$/,
        use: [
          {
            loader: 'sass-loader',
            options: {
              sassOptions: {
                importer: globImporter()
              }
            }
          }
        ]
      }
    ]
  },
  plugins: [
    new Dotenv()
  ]
}

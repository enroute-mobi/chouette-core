const globImporter = require('node-sass-glob-importer')
const webpack = require('webpack')
const SentryWebpackPlugin = require("@sentry/webpack-plugin");

module.exports = {
  devtool: "source-map",
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
    new webpack.DefinePlugin({
      'process.env': {
        NODE_ENV: JSON.stringify(process.env.NODE_ENV)
      }
    })
  ]
}

// Load this plugin only when running webpack in a production environment
if (process.env.SENTRY_AUTH_TOKEN) {
  console.log("SentryWebpackPlugin push source-map to sentry")
  module.exports.plugins.push(
    new SentryWebpackPlugin({
      org: "enroute",
      project: "chouette",

      // Specify the directory containing build artifacts
      include: [
        {
          paths: ['./public/packs/js'],
          urlPrefix: '~/packs/js',
        },
      ],

      // Auth tokens can be obtained from https://sentry.io/settings/account/api/auth-tokens/
      // and needs the `project:releases` and `org:read` scopes
      authToken: process.env.SENTRY_AUTH_TOKEN,

      // Optionally uncomment the line below to override automatic release name detection
      release: process.env.VERSION,
    }),
  );
  console.log(module.exports)
}

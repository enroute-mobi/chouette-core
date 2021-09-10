module.exports = {
  module: {
    rules: [
      {
        test: /\.m?js$/,
        exclude: /(node_modules|bower_components)/,
        use: {
          loader: 'babel-loader',
          options: {
            presets: ['@babel/preset-env',"@babel/preset-react"]
          }
        }
      },
      {
        test: /\.coffee(\.erb)?$/,
        use: [{
          loader: 'coffee-loader'
        }]
      },
      {
        test:     /\.erb$/,
        enforce:  "pre",
        exclude:  /node_modules/,

        use: [{
          loader:   "rails-erb-loader",
          options:  {
            runner:     (/^win/.test(process.platform) ? "ruby " : "") + "bin/rails runner",
            env:        {
              ...process.env,
              DISABLE_SPRING: 1,
            },
          },
        }],
      },
      {
        test: /\.(woff(2)?|ttf|eot|svg)(\?v=\d+\.\d+\.\d+)?$/,
        use: [
          {
            loader: 'file-loader',
            options: {
              name: '[name].[ext]',
              outputPath: 'fonts/'
            }
          }
        ]
      }
    ]
  }
}
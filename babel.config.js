{
  "presets": [
    ["es2015"], ["react"]
  ],
  "plugins": [
    "transform-async-to-generator",
    "transform-es2015-spread",
    "transform-object-rest-spread"
  ],

  "env": {
    "test": {
      "plugins": [
        "transform-es2015-modules-commonjs",
      ]
    }
  }
}
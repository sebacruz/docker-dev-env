var path = require('path');

module.exports = {
  entry: './resources/index.js',
  output: {
    filename: 'bundle.js',
    path: path.resolve(__dirname, 'public/assets')
  },
  devServer: {
    port: 5001
  }
};

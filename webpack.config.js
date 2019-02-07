/*jshint esversion: 6 */


// jxa plugin creates an executable .js file for each of the webpack entry points defined below.
const JxaPlugin = require("./src/plugin/jxa-plugin");

// exec exported function plugin creates an executable .js file that will simply `module.exports(argv)`.
const ExecExportedFunctionPlugin = require("./src/plugin/exec-exported-function-plugin");

const WebpackShellPlugin = require('webpack-shell-plugin');



const webpack = require('webpack')
const path = require('path')


/*
 * We've enabled UglifyJSPlugin for you! This minifies your app
 * in order to load faster and run less javascript.
 *
 * https://github.com/webpack-contrib/uglifyjs-webpack-plugin
 *
 */

const UglifyJSPlugin = require('uglifyjs-webpack-plugin');




/*
 * We've enabled commonsChunkPlugin for you. This allows your app to
 * load faster and it splits the modules you provided as entries across
 * different bundles!
 *
 * https://webpack.js.org/plugins/commons-chunk-plugin/
 *
 */



module.exports = [{
  devtool: 'inline-source-map',

  entry: {
    "probe-windows": "./src/probe-windows.coffee",
    "close-windows": "./src/close-windows.coffee",
    "make-window": "./src/make-window.coffee",
    "make-tab": "./src/make-tab.coffee",
    "safari-scan-tabs": "./src/safari-scan-tabs.js",
  },

  output: {
    filename: '[name].js',
    chunkFilename: '[name].[chunkhash].js',
    path: path.resolve(__dirname, 'dist')
  },

  module: {
    rules: [
      {
        test: /\.coffee$/,
        use: [ 'coffee-loader' ]
      }
    ]
  },

  resolve: {
    extensions: [".web.coffee", ".web.js", ".coffee", ".js"]
  },

  plugins: [
    // new UglifyJSPlugin(),
    new JxaPlugin(),
  ]
},

// lib scripts to test.
{
  devtool: 'inline-source-map',

  entry: {
    "newWindow_openCmd": "./src/lib/newWindow_openCmd.coffee"
  },

  output: {
    filename: '[name].js',
    chunkFilename: '[name].[chunkhash].js',
    path: path.resolve(__dirname, 'dist')
  },

  module: {
    rules: [
      {
        test: /\.coffee$/,
        use: [ 'coffee-loader' ]
      }
    ]
  },

  resolve: {
    extensions: [".web.coffee", ".web.js", ".coffee", ".js"]
  },

  plugins: [
    new ExecExportedFunctionPlugin(),
  ]
}];

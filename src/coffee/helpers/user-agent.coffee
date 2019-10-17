{ arch, platform } = require 'os'

module.exports = (pkgName, pkgVersion) =>
  throw new Error 'Package name and version is required' unless pkgName and pkgVersion
  sdkPkgVersion = require '../package.json'.version
  nodeInfo = "Node.js/#{process.version}"
  runtimeInfo = "#{platform()}; #{arch()}"
  moduleInfo = "#{pkgName}/#{pkgVersion}"

  "node-sdk/#{sdkPkgVersion} #{nodeInfo} (#{runtimeInfo}) #{moduleInfo}"

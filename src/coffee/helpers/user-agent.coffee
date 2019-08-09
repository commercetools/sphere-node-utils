{ arch, platform } = require 'os'
{ SphereClient } = require 'sphere-node-sdk'

module.exports = (pkgName, pkgVersion) =>
  throw new Error 'Package name and version is required' unless pkgName and pkgVersion
  sdkPkgVersion = SphereClient.getVersion
  nodeInfo = "Node.js/#{process.version}"
  runtimeInfo = "#{platform()}; #{arch()}"
  moduleInfo = "#{pkgName}/#{pkgVersion}"

  "node-sdk/#{sdkPkgVersion} #{nodeInfo} (#{runtimeInfo}) #{moduleInfo}"

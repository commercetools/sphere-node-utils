{ arch, platform } = require 'os'
getPkg = require 'load-module-pkg'

module.exports = (pkgName, pkgVersion) =>
  throw new Error 'Package name and version is required' unless pkgName and pkgVersion
  sdkPkgVersion = getPkg('sphere-node-sdk').version
  throw new Error "'sphere-node-sdk' is required to generate the user-agent" unless sdkPkgVersion
  nodeInfo = "Node.js/#{process.version}"
  runtimeInfo = "#{platform()}; #{arch()}"
  moduleInfo = "#{pkgName}/#{pkgVersion}"

  "#{sdkPkgVersion} #{nodeInfo} (#{runtimeInfo}) #{moduleInfo}"

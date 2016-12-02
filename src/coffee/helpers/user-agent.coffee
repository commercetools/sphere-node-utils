{ arch, platform } = require 'os'
getPkg = require 'load-module-pkg'

module.exports = (pkgName, pkgVersion) =>
  throw new Error 'Package name and version is required' unless pkgName and pkgVersion
  sdkPkgVersion = getPkg('sphere-node-sdk').version
  nodeInfo = "Node.js/#{process.version}"
  runtimeInfo = "#{platform()}; #{arch()}"
  moduleInfo = "#{pkgName}/#{pkgVersion}"

  "#{sdkPkgVersion} #{nodeInfo} (#{runtimeInfo}) #{moduleInfo}"

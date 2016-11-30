{ arch, platform } = require 'os'
getPkg = require 'load-module-pkg'
getSelfPkg = require 'load-pkg'

module.exports = (pkgName) =>
  throw new Error 'Package name is required' unless pkgName
  curPkg = getPkg(pkgName)
  curPkg = getSelfPkg.sync(process.cwd()) unless curPkg.name
  sdkPkgVersion = getPkg('sphere-node-sdk').version
  throw new Error "Package name #{pkgName} is not present in node_modules or current project package.json" unless curPkg.name is pkgName
  throw new Error "'sphere-node-sdk' is required to generate the user-agent" unless sdkPkgVersion
  nodeInfo = "Node.js/#{process.version}"
  runtimeInfo = "#{platform()}; #{arch()}"
  moduleInfo = "#{curPkg.name}/#{curPkg.version}"

  "#{sdkPkgVersion} #{nodeInfo} (#{runtimeInfo}) #{moduleInfo}"

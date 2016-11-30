Promise = require 'bluebird'
{ userAgent } = require '../../lib/main'
loadPkg = require 'load-pkg'
describe 'UserAgent', ->

  it 'should fetch useragent of any installed module', ->
    curPkg = loadPkg.sync(process.cwd())
    curUserAgent = userAgent('sphere-node-utils', curPkg.version)
    expect(curUserAgent).toBeDefined()
    expect(curUserAgent).toMatch(curPkg.version)

  it 'should throw error if package name is not given', ->
    expect(userAgent).toThrow()

  it 'should throw error if package is not installed', ->
    expect(() -> userAgent('sphere-node-utils-invalid')).toThrow()

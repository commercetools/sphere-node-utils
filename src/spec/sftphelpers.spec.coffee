_ = require 'underscore'
SftpHelpers = require '../lib/sftphelpers'
Config = require '../config'

describe 'SftpHelpers', ->
  beforeEach ->
    @helpers = new SftpHelpers Config.config

  it 'should be initialized', ->
    expect(@helpers).toBeDefined()

  it 'should open a sftp connection', (done) ->
    @helpers.openSftp().then (sftp) =>
      expect(sftp).toBeDefined()
      @helpers.close sftp
      done()
    .fail (result) ->
      console.log result
      expect(true).toBe false
      done()

  it 'should list files', (done) ->
    @sftp
    @helpers.openSftp()
    .then (sftp) =>
      @sftp = sftp
      @helpers.listFiles(sftp, '/upload/data')
    .then (files) =>
      expect(_.size files).toBeGreaterThan 0
      @helpers.close @sftp
      done()
    .fail (result) =>
      @helpers.close @sftp
      done(result)

_ = require 'underscore'
SftpHelpers = require '../lib/sftphelpers'
Config = require '../config'
fs = require 'fs'

describe 'SftpHelpers', ->

  REMOTE_ROOT = '/upload'

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
      @helpers.listFiles(sftp, "#{REMOTE_ROOT}/data")
    .then (files) =>
      expect(_.size files).toBeGreaterThan 0
      @helpers.close @sftp
      done()
    .fail (result) =>
      @helpers.close @sftp
      done(result)

  describe 'getFile()', ->

    TEST_FILE = 'test.txt'

    afterEach (done) ->
      fs.unlink "./#{TEST_FILE}", (err) ->
        if err
          done(err)
        else
          done()

    it 'should download file from remote server', (done) ->

      @sftp
      @helpers.openSftp().then (sftp) =>
        @sftp = sftp
        @helpers.getFile(sftp, "#{REMOTE_ROOT}/#{TEST_FILE}", "./#{TEST_FILE}").then =>
          expect(fs.existsSync(TEST_FILE)).toBe true
          @helpers.close @sftp
          done()
      .fail (result) ->
        @helpers.close @sftp
        done(result)

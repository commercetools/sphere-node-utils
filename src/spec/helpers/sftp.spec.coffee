fs = require 'fs'
Q = require 'q'
_ = require 'underscore'
Connection = require 'ssh2'
SftpConfig = require('../../config').config.sftp
SftpHelpers = require '../../lib/helpers/sftp'
Logger = require '../../lib/helpers/logger'

describe 'SftpHelpers', ->

  TEST_FILE = 'test.txt'
  ROOT_REMOTE = '/upload'
  ROOT_LOCAL = "#{__dirname}/../.."
  FOLDER_LOCAL = "#{ROOT_LOCAL}/tmp-test"
  FOLDER_REMOTE = "#{ROOT_REMOTE}/data"
  FILE_REMOTE = "#{FOLDER_REMOTE}/#{TEST_FILE}"
  FILE_REMOTE_RENAMED = "#{FOLDER_REMOTE}/renamed-#{TEST_FILE}"
  FILE_LOCAL = "#{ROOT_LOCAL}/data/#{TEST_FILE}"
  FILE_LOCAL_DOWNLOAD = "#{FOLDER_LOCAL}/#{TEST_FILE}"

  beforeEach (done) ->
    @logger = new Logger
      streams: [
        level: 'info', stream: process.stdout
      ]
    @helpers = new SftpHelpers _.extend {}, SftpConfig,
      logger: @logger

    @helpers.openSftp()
    .then (sftp) =>
      @_sftp = sftp
      @logger.debug FILE_LOCAL, 'Local file path'
      @logger.debug FILE_REMOTE, 'Remote file path'
      @helpers.safePutFile sftp, FILE_LOCAL, FILE_REMOTE
    .then =>
      @logger.debug 'File uploaded'
      done()
    .fail (error) =>
      @helpers.close @_sftp
      done(error)
    .done()
  , 20000 # 20sec

  afterEach (done) ->
    @logger.debug 'About to remove all remote files'
    @helpers.listFiles @_sftp, FOLDER_REMOTE
    .then (files) =>
      @logger.debug files
      Q.all _.filter(files, (f) ->
        switch f.filename
          when '.', '..' then false
          else true
      ).map (f) =>
        @logger.debug "About to remove #{f.filename}"
        @helpers.removeFile @_sftp, "#{FOLDER_REMOTE}/#{f.filename}"
      .then =>
        @helpers.close @_sftp
        done()
      .fail (error) -> done(error)
    .fail (error) ->
      if error.message is 'No such file'
        done()
      else
        done(error)
    .done()
  , 15000 # 15sec

  it 'should be initialized', ->
    expect(@helpers).toBeDefined()

  it 'should open a sftp connection', ->
    expect(@_sftp).toBeDefined()

  it 'should list files', (done) ->
    @helpers.listFiles(@_sftp, FOLDER_REMOTE)
    .then (files) ->
      expect(_.size files).toBeGreaterThan 0
      done()
    .fail (error) -> done(error)
    .done()

  it 'should get file stats', (done) ->
    @helpers.stats(@_sftp, FILE_REMOTE)
    .then (stat) ->
      expect(stat.isFile()).toBe true
      done()
    .fail (error) -> done(error)
    .done()

  it 'should download file from remote server', (done) ->
    @helpers.getFile @_sftp, FILE_REMOTE, FILE_LOCAL_DOWNLOAD
    .then ->
      expect(fs.existsSync(FILE_LOCAL_DOWNLOAD)).toBe true
      done()
    .fail (error) -> done(error)
    .done()

  it 'should handle error properly', (done) ->
    @helpers.getFile @_sftp, '/wrong', FILE_LOCAL_DOWNLOAD
    .then -> done('Should not happen')
    .fail (error) ->
      expect(error).toBeDefined()
      done()
    .done()
  , 30000 # 30sec

  it 'should move a file on remote server', (done) ->
    fileRemote2 = "#{FOLDER_REMOTE}/test2.txt"
    @helpers.putFile @_sftp, FILE_LOCAL, fileRemote2
    .then => @helpers.moveFile @_sftp, fileRemote2, FILE_REMOTE_RENAMED
    .then => @helpers.stats @_sftp, FILE_REMOTE_RENAMED
    .then (stat) =>
      expect(stat.isFile()).toBe true
      @helpers.removeFile @_sftp, FILE_REMOTE_RENAMED
    .then -> done()
    .fail (error) -> done(error)
    .done()

  it 'should handle error properly when moving wrong file', (done) ->
    @helpers.moveFile @_sftp, '/wrong/bla', '/wrong/blubb'
    .then -> done('Should not happen')
    .fail (error) ->
      expect(error).toBeDefined()
      done()
    .done()
  , 30000 # 30sec

  it 'should download all files from remote server', (done) ->
    fileRemoteA = "#{FOLDER_REMOTE}/testA.txt"
    fileRemoteB = "#{FOLDER_REMOTE}/testB.txt"
    @helpers.putFile @_sftp, FILE_LOCAL, fileRemoteA
    .then => @helpers.putFile @_sftp, FILE_LOCAL, fileRemoteB
    .then => @helpers.downloadAllFiles @_sftp, FOLDER_LOCAL, FOLDER_REMOTE
    .then ->
      expect(fs.existsSync("#{FOLDER_LOCAL}/testA.txt")).toBe true
      expect(fs.existsSync("#{FOLDER_LOCAL}/testB.txt")).toBe true
      done()
    .fail (error) -> done(error)
    .done()

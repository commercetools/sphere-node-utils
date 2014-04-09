fs = require 'fs'
Q = require 'q'
_ = require 'underscore'
Connection = require 'ssh2'
SftpConfig = require('../../config').config.sftp
SftpHelpers = require '../../lib/helpers/sftp'

describe 'SftpHelpers', ->

  TEST_FILE = 'test.txt'
  ROOT_REMOTE = '/upload'
  FILE_REMOTE = "#{ROOT_REMOTE}/#{TEST_FILE}"
  FOLDER_REMOTE = "#{ROOT_REMOTE}/data"
  FILE_LOCAL = "data/#{TEST_FILE}"
  FILE_LOCAL_DOWNLOAD = "./#{TEST_FILE}"

  beforeEach (done) ->
    @helpers = new SftpHelpers SftpConfig

    # initialize sftp session used for validating remote changes
    @_conn = new Connection()

    @_conn.on 'ready', =>
      @_conn.sftp (err, sftp) =>
        if err
          done(err)
        else
          @_sftp = sftp
          done()

    @_conn.connect
      host: SftpConfig.host
      username: SftpConfig.username
      password: SftpConfig.password

  afterEach (done) ->
    @_sftp.end()
    @_conn.end()
    done()

  it 'should be initialized', ->
    expect(@helpers).toBeDefined()

  it 'should open a sftp connection', (done) ->
    @helpers.openSftp().then (sftp) =>
      expect(sftp).toBeDefined()
      @helpers.close sftp
      done()
    .fail (error) -> done(error)
    .fin => @helpers.close @sftp
    .done()
  , 10000 # 10sec

  it 'should list files', (done) ->
    @sftp
    @helpers.openSftp()
    .then (sftp) =>
      @sftp = sftp
      @helpers.listFiles(sftp, FOLDER_REMOTE)
    .then (files) =>
      expect(_.size files).toBeGreaterThan 0
      @helpers.close @sftp
      done()
    .fail (error) -> done(error)
    .fin => @helpers.close @sftp
    .done()
  , 10000 # 10sec

  describe 'getFile()', ->

    beforeEach (done) ->
      @_sftp.fastPut FILE_LOCAL, FILE_REMOTE, (err) ->
        if err
          done(err)
        else
          done()

    afterEach (done) ->
      removeLocalFile FILE_LOCAL_DOWNLOAD
      .then =>
        removeRemoteFile(@_sftp, FILE_REMOTE)
        done()
      .fail (error) -> done(error)
      .done()

    it 'should download file from remote server', (done) ->

      @sftp
      @helpers.openSftp()
      .then (sftp) =>
        @sftp = sftp
        @helpers.getFile(sftp, FILE_REMOTE, FILE_LOCAL_DOWNLOAD)
      .then =>
        expect(fs.existsSync(TEST_FILE)).toBe true
        @helpers.close @sftp
        done()
      .fail (error) -> done(error)
      .fin => @helpers.close @sftp
      .done()
    , 10000 # 10sec

    it 'should handle error properly', (done) ->

      @sftp
      @helpers.openSftp()
      .then (sftp) =>
        @sftp = sftp
        @helpers.getFile(sftp, '/wrong', FILE_LOCAL_DOWNLOAD)
      .then =>
        @helpers.close @sftp
        done('should call fail() method.')
      .fail (error) -> done(error)
      .fin => @helpers.close @sftp
      .done()
    , 10000 # 10sec

  describe 'moveFile()', ->

    FILE_REMOTE_RENAMED = "#{ROOT_REMOTE}/renamed-#{TEST_FILE}"

    beforeEach (done) ->
      @_sftp.fastPut FILE_LOCAL, FILE_REMOTE, (err) ->
        if err
          done(err)
        else
          done()

    afterEach (done) ->

      removeRemoteFile(@_sftp, FILE_REMOTE_RENAMED)
      .then =>
        removeRemoteFile(@_sftp, FILE_REMOTE)
      .then -> done()
      .fail (error) -> done(error)
      .done()

    it 'should move a file on remote server', (done) ->

      @sftp
      @helpers.openSftp()
      .then (sftp) =>
        @sftp = sftp
        @helpers.moveFile(sftp, FILE_REMOTE, FILE_REMOTE_RENAMED)
      .then =>
        existsRemoteFile @_sftp, FILE_REMOTE_RENAMED
      .then (exists) =>
        expect(exists).toBe true
        @helpers.close @sftp
        done()
      .fail (error) -> done(error)
      .fin => @helpers.close @sftp
      .done()
    , 10000 # 10sec

    it 'should handle error properly', (done) ->

      @sftp
      @helpers.openSftp()
      .then (sftp) =>
        @sftp = sftp
        @helpers.moveFile(sftp, '/wrong/bla', '/wrong/blubb')
      .then =>
        @helpers.close @sftp
        done('should call fail() method.')
      .fail (error) -> done(error)
      .fin => @helpers.close @sftp
      .done()
    , 10000 # 10sec

  ##################
  # helper methods #
  ##################

  ###
  Remove local file if existing.
  @param {string} path Path to resource.
  @return Promise
  ###
  removeLocalFile = (path) ->
    deferred = Q.defer()
    fs.exists path, (exists) ->
      if exists
        fs.unlink path, (err) ->
          if err
            deferred.reject err
          else
            deferred.resolve()
      else
        deferred.resolve()

    deferred.promise

  ###
  Remove remote file if existing.
  @param {object} sftp SFTP handle.
  @param {string} path Path to resource.
  @return Promise
  ###
  removeRemoteFile = (sftp, path) ->
    deferred = Q.defer()
    sftp.unlink path, (err) ->
      if err
        if err.message is 'No such file'
          deferred.resolve false
        else
          deferred.reject err
      else
        deferred.resolve()

    deferred.promise

  ###
  Checks if resource exists.
  @param {object} sftp SFTP handle.
  @param {string} path Path to resource.
  @return Returns 'true' if file exists, otherwise 'false'.
  ###
  existsRemoteFile = (sftp, path) ->
    deferred = Q.defer()
    sftp.stat path, (err, stats) ->
      if err
        if err.message is 'No such file'
          deferred.resolve false
        else
          deferred.reject err
      else
        deferred.resolve true

    deferred.promise

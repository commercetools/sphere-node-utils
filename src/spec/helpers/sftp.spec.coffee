debug = require('debug')('spec:sftp')
_ = require 'underscore'
Promise = require 'bluebird'
fs = Promise.promisifyAll require('fs')
Connection = require 'ssh2'
SftpConfig = require('../../config').config.sftp
{Sftp} = require '../../lib/main'

fsExistsAsync = (path) ->
  new Promise (resolve, reject) ->
    fs.exists path, (exists) ->
      if exists
        resolve(true)
      else
        resolve(false)

fsRmDirRecursive = (path) ->
  new Promise (resolve, reject) ->
    # TODO: make it async
    _rmRecursive = ->
      if fs.existsSync(path)
        for file in fs.readdirSync(path)
          currPath = "#{path}/#{file}"
          if fs.lstatSync(currPath).isDirectory()
            _rmRecursive(currPath)
          else
            fs.unlinkSync(currPath)
        fs.rmdirSync(path)
    _rmRecursive()
    resolve()

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
    @helpers = new Sftp _.extend({}, SftpConfig, debug: false)
    # sftpDisposer = =>
    #   @helpers.openSftp().disposer (sftp) => @helpers.close sftp
    # Promise.using sftpDisposer(), (sftp) =>
    @helpers.openSftp()
    .then (sftp) =>
      @_sftp = sftp
      debug 'local file path: %s', FILE_LOCAL
      debug 'remote file path: %s', FILE_REMOTE
      @helpers.safePutFile sftp, FILE_LOCAL, FILE_REMOTE
    .then ->
      debug 'File uploaded'
      done()
    .catch (error) -> done(error)
    .done()
  , 20000 # 20sec

  afterEach (done) ->
    debug 'About to remove all remote files'
    # sftpDisposer = =>
    #   @helpers.listFiles(@_sftp, FOLDER_REMOTE).disposer => @helpers.close @_sftp
    # Promise.using sftpDisposer(), (files) =>
    @helpers.listFiles(@_sftp, FOLDER_REMOTE)
    .then (files) =>
      debug 'files to be removed: %j', files
      Promise.all _.filter(files, (f) ->
        switch f.filename
          when '.', '..', 'processed' then false
          else true
      ).map (f) =>
        debug "About to remove #{f.filename}"
        @helpers.removeFile @_sftp, "#{FOLDER_REMOTE}/#{f.filename}"
      .then =>
        @helpers.close @_sftp
        done()
      .catch (error) -> done(error)
    .catch (error) ->
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
    .catch (error) -> done(error)
    .done()

  it 'should list files in large directories', (done) ->
    Promise.map [1..100], (i) =>
      @helpers.safePutFile @_sftp, FILE_LOCAL, FOLDER_REMOTE + "/test#{i}.txt"
    , {concurrency: 5}
    .then =>
      @helpers.listFiles(@_sftp, FOLDER_REMOTE)
    .then (files) ->
      expect(_.size files).toEqual 100
      done()
    .catch (error) -> done(error)
  , 30000 # 30sec

  it 'should get file stats', (done) ->
    @helpers.stats(@_sftp, FILE_REMOTE)
    .then (stat) ->
      expect(stat.isFile()).toBe true
      done()
    .catch (error) -> done(error)
    .done()

  it 'should download file from remote server', (done) ->
    fsExistsAsync(FOLDER_LOCAL)
    .then (exists) ->
      if exists
        Promise.resolve() # folder exists, continue
      else
        fs.mkdirAsync(FOLDER_LOCAL)
    .then => @helpers.getFile @_sftp, FILE_REMOTE, FILE_LOCAL_DOWNLOAD
    .then -> fsExistsAsync(FILE_LOCAL_DOWNLOAD)
    .then (exists) ->
      expect(exists).toBe true
      Promise.resolve()
    .then -> fsRmDirRecursive(FOLDER_LOCAL)
    .then -> done()
    .catch (error) -> done(error)
    .done()

  it 'should handle error properly', (done) ->
    @helpers.getFile @_sftp, '/wrong', FILE_LOCAL_DOWNLOAD
    .then -> done('Should not happen')
    .catch (error) ->
      expect(error).toBeDefined()
      done()
    .done()
  , 30000 # 30sec

  it 'should move a file on remote server', (done) ->
    fileRemote2 = "#{FOLDER_REMOTE}/test2.txt"
    @helpers.putFile @_sftp, FILE_LOCAL, fileRemote2
    .then => @helpers.renameFile @_sftp, fileRemote2, FILE_REMOTE_RENAMED
    .then => @helpers.stats @_sftp, FILE_REMOTE_RENAMED
    .then (stat) =>
      expect(stat.isFile()).toBe true
      @helpers.removeFile @_sftp, FILE_REMOTE_RENAMED
    .then -> done()
    .catch (error) -> done(error)
    .done()

  it 'should safely move a file to a subfolder on remote server', (done) ->
    fileRemote2 = "#{FOLDER_REMOTE}/test2.txt"
    dirFileRemote2Renamed = "#{FOLDER_REMOTE}/processed/renamed-#{TEST_FILE}"
    @helpers.putFile @_sftp, FILE_LOCAL, fileRemote2
    .then => @helpers.safeRenameFile @_sftp, fileRemote2, dirFileRemote2Renamed
    .then => @helpers.stats @_sftp, dirFileRemote2Renamed
    .then (stat) =>
      expect(stat.isFile()).toBe true
      @helpers.removeFile @_sftp, dirFileRemote2Renamed
    .then -> done()
    .catch (error) -> done(error)
    .done()

  it 'should handle error properly when moving wrong file', (done) ->
    @helpers.renameFile @_sftp, '/wrong/bla', '/wrong/blubb'
    .then -> done('Should not happen')
    .catch (error) ->
      expect(error).toBeDefined()
      done()
    .done()
  , 30000 # 30sec

  it 'should download all files from remote server', (done) ->
    fileRemoteA = "#{FOLDER_REMOTE}/testA.txt"
    fileRemoteB = "#{FOLDER_REMOTE}/testB.txt"
    fsExistsAsync(FOLDER_LOCAL)
    .then (exists) ->
      if exists
        Promise.resolve() # folder exists, continue
      else
        fs.mkdirAsync(FOLDER_LOCAL)
    .then => @helpers.putFile @_sftp, FILE_LOCAL, fileRemoteA
    .then => @helpers.putFile @_sftp, FILE_LOCAL, fileRemoteB
    .then => @helpers.downloadAllFiles @_sftp, FOLDER_LOCAL, FOLDER_REMOTE
    .then -> Promise.all [fsExistsAsync("#{FOLDER_LOCAL}/testA.txt"), fsExistsAsync("#{FOLDER_LOCAL}/testB.txt")]
    .spread (existsA, existsB) ->
      expect(existsA).toBe true
      expect(existsB).toBe true
      Promise.resolve()
    .then -> fsRmDirRecursive(FOLDER_LOCAL)
    .then -> done()
    .catch (error) -> done(error)
    .done()

  it 'should safely upload multiple files sequentially with same name (no force overwrite)', (done) ->
    Promise.map [1..3], =>
      @helpers.safePutFile @_sftp, FILE_LOCAL, FILE_REMOTE, false
    , {concurrency: 1}
    .then -> done()
    .catch (error) -> done(error)
  , 30000 # 30sec

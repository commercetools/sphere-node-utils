debug = require('debug')('sftp')
_ = require 'underscore'
Promise = require 'bluebird'
Connection = require 'ssh2'

uniqueId = (prefix) ->
  _.uniqueId "#{prefix}#{new Date().getTime()}_"

class Sftp

  constructor: (@_options = {}) ->

  ###*
   * Get directory entries.
   * @param {Object} sftp SFTP handle
   * @param {String} dirName Directory to get the entries from
   * @return {Promise} A promise, fulfilled with an {Array} or rejected with an error
  ###
  listFiles: (sftp, dirName) ->
    new Promise (resolve, reject) ->
      sftp.opendir dirName, (err, handle) ->
        if err
          reject err
        else
          sftp.readdir handle, (err, list) ->
            if err
              reject err
            else
              if list is false
                resolve [] # return an empty array
              else
                resolve list
            sftp.close handle

  ###*
   * {@link https://github.com/mscdex/ssh2#stats}
   * Get directory statistics (useful to check if file is directory or file)
   * @param {Object} sftp SFTP handle
   * @param {String} path Path to the file where to get the stats from
   * @return {Promise} A promise, fulfilled with an {Array} or rejected with an error
  ###
  stats: (sftp, path) ->
    new Promise (resolve, reject) ->
      sftp.stat path, (err, stats) ->
        if err
          reject err
        else
          resolve stats

  readFile: (fileName) ->
    # TODO

  saveFile: (path, fileName, content) ->
    # TODO

  ###*
   * Download a file.
   * @param {Object} sftp SFTP handle
   * @param {String} remotePath Path of the remote file
   * @param {String} localPath Download file to this path
   * @return {Promise} A promise, fulfilled with an {Object} or rejected with an error
  ###
  getFile: (sftp, remotePath, localPath) ->
    new Promise (resolve, reject) ->
      sftp.fastGet remotePath, localPath, (err) ->
        if err
          reject err
        else
          resolve()

  ###*
   * Upload a file.
   * @param {Object} sftp SFTP handle
   * @param {String} localPath Upload file to this path
   * @param {String} remotePath Path of the remote file
   * @return {Promise} A promise, fulfilled with an {Object} or rejected with an error
  ###
  putFile: (sftp, localPath, remotePath) ->
    new Promise (resolve, reject) ->
      sftp.fastPut localPath, remotePath, (err) ->
        if err
          reject err
        else
          resolve()

  ###*
   * Upload a file safely by temporarly upload it to a tmp folder, moving it then into the
   * given target path to assure that it's there.
   * @param {Object} sftp SFTP handle
   * @param {String} localPath Upload file to this path
   * @param {String} remotePath Path of the remote file
   * @return {Promise} A promise, fulfilled with an {Object} or rejected with an error
  ###
  safePutFile: (sftp, localPath, remotePath, forceOverwrite = true) ->
    tmpName = "#{remotePath}_#{uniqueId('tmp')}"
    debug "About to upload file #{localPath}"
    canUpload = (fileName) =>
      if forceOverwrite
        debug 'Force overwrite is true, proceed with upload'
        Promise.resolve()
      else
        debug "Force overwrite is false, checking if #{fileName} exists"
        @stats(sftp, fileName)
        .then (stat) ->
          if stat.isFile()
            Promise.reject "Uploading file #{fileName} already exists on the remote server and cannot proceed unless I'm being forced to"
          else
            debug "File #{fileName} doesn't appear to be a file, proceeding with upload"
            Promise.resolve()
        .catch ->
          debug "File #{fileName} not found, proceeding with upload"
          Promise.resolve()

    canUpload(tmpName)
    .then => @putFile(sftp, localPath, tmpName)
    .then =>
      debug "File uploaded as #{tmpName}"
      @stats(sftp, tmpName)
    .then (stat) =>
      if stat.isFile()
        # file has been successfully uploaded, move it to correct path
        debug "File check successful, about to rename it"
        @safeRenameFile(sftp, tmpName, remotePath)
      else
        # failure, cleanup before rejecting
        debug "File check failed, about to cleanup #{tmpName}"
        @removeFile(sftp, tmpName)
        .then -> Promise.reject 'File upload check failed'

  ###*
   * Rename a remote resource.
   * @param {Object} sftp SFTP handle
   * @param {String} srcPath Source path of the remote resource
   * @param {String} destPath Destination path of the remote resource
   * @return {Promise} A promise, fulfilled with an {Object} or rejected with an error
  ###
  renameFile: (sftp, srcPath, destPath) ->
    new Promise (resolve, reject) ->
      sftp.rename srcPath, destPath, (err) ->
        if err
          reject err
        else
          resolve()

  ###*
   * Rename a remote resource safely, by checking if it's there first and remove it if so.
   * @param {Object} sftp SFTP handle
   * @param {String} srcPath Source path of the remote resource
   * @param {String} destPath Destination path of the remote resource
   * @return {Promise} A promise, fulfilled with an {Object} or rejected with an error
  ###
  safeRenameFile: (sftp, srcPath, destPath) ->
    ### WORKAROUND
    Unfortunately, rename will fail if there is already an existing file with the same name.
    To avoid that, we should remove first the old file, then rename the new one
    ###
    debug "About to safe rename the file #{srcPath} to #{destPath}"
    @stats(sftp, destPath)
    .then (stat) =>
      debug "File #{destPath} already exist, about to remove it before rename it"
      if stat.isFile()
        @removeFile(sftp, destPath)
        .then =>
          debug "File #{destPath} removed, about to rename it"
          @renameFile(sftp, srcPath, destPath)
          .then -> Promise.resolve()
          .catch (err) ->
            debug "Failed to rename file #{destPath} during safeRename"
            Promise.reject err
        .catch (err) ->
          # log this message in order to better identify the problem (sftp errors are not that useful)
          # and pass the error to the next handler
          debug "Failed to remove file #{destPath} during safeRename"
          Promise.reject err
      else
        Promise.reject "The resource at #{destPath} already exist and it doesn't appear to be a file. Please check that what you want to rename is a file."
    .catch (err) =>
      if err.message is 'No such file'
        debug "File #{destPath} doesn't exist, about to rename it"
        @renameFile(sftp, srcPath, destPath)
      else
        Promise.reject err

  ###*
   * Remove remote file
   * @param {Object} sftp SFTP handle
   * @param {String} path Path to the remote file
   * @return {Promise} A promise, fulfilled with an {Array} or rejected with an error
  ###
  removeFile: (sftp, path) ->
    new Promise (resolve, reject) ->
      sftp.unlink path, (err) ->
        if err
          reject err
        else
          resolve()

  ###*
   * Starts a SFTP session.
   * @return {Promise} A promise, fulfilled with an {Object} or rejected with an error
  ###
  openSftp: ->
    new Promise (resolve, reject) =>
      @conn = new Connection()

      @conn.on 'ready', =>
        debug 'Connection :: ready'
        @conn.sftp (err, sftp) ->
          if err
            reject err
          else
            sftp.on 'end', -> debug 'SFTP :: end'
            resolve sftp
      @conn.on 'error', (err) ->
        debug err, 'Connection :: error'
        reject err
      @conn.on 'close', (hadError) ->
        debug "Connection :: close - had error: #{hadError}"
        reject 'Error on closing SFTP connection' if hadError
      @conn.on 'end', ->
        debug 'Connection :: end'

      connectOpts =
        host: @_options.host
        username: @_options.username
        password: @_options.password
      if @_options.port
        connectOpts['port'] = @_options.port
      if @_options.debug
        connectOpts['debug'] = (msg) -> debug msg
      @conn.connect connectOpts

  ###*
   * Close SFTP session and underlying connection.
   * @param {Object} sftp SFTP handle
   * @return {Promise} A promise, fulfilled with an {Object} or rejected with an error
  ###
  close: (sftp) ->
    sftp.end() if sftp
    @conn.end()

  ###*
   * Download all files from a given remote folder (exclude '.', '..' and directories)
   * @param {Object} sftp SFTP handle
   * @param {String} tmpFolder Local tmp folder path where to save the files to
   * @param {String} remoteFolder Remote path folder where to download the files from
   * @param {String} [fileRegex] A RegExp to be applied when filtering files
   * @param {Number} [maxConcurrency=3] maximum number of concurrent downloads from SFTP
   * @return {Promise} A promise, fulfilled with an {Object} or rejected with an error
  ###
  downloadAllFiles: (sftp, tmpFolder, remoteFolder, fileRegex = '', maxConcurrency = 3) ->
    new Promise (resolve, reject) =>
      @listFiles(sftp, remoteFolder)
      .then (files) =>
        debug files, 'List of files'
        regex = new RegExp(fileRegex)
        filteredFiles = _.filter files, (f) ->
          switch f.filename
            when '.', '..' then false
            else regex.test(f.filename)
        Promise.map filteredFiles, ((f) =>
          @stats(sftp, "#{remoteFolder}/#{f.filename}")),
          concurrency: maxConcurrency
        .then (stats) =>
          filesOnly = []
          _.each filteredFiles, (f, i) -> filesOnly.push(f) if stats[i].isFile() # here magic happens!
          debug filesOnly, "About to download"
          Promise.map filesOnly, ((f) =>
            @getFile(sftp, "#{remoteFolder}/#{f.filename}", "#{tmpFolder}/#{f.filename}")),
            concurrency: maxConcurrency
        .then -> resolve()
      .catch (error) -> reject error

module.exports = Sftp

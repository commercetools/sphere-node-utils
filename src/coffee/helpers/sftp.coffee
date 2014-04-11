Q = require 'q'
_ = require 'underscore'
Connection = require 'ssh2'

uniqueId = (prefix) ->
  _.uniqueId "#{prefix}#{new Date().getTime()}_"

class Sftp

  constructor: (@_options = {}) ->
    {@logger} = @_options

  ###*
   * Get directory entries.
   * @param {Object} sftp SFTP handle
   * @param {String} dirName Directory to get the entries from
   * @return {Promise} A promise, fulfilled with an {Array} or rejected with an error
  ###
  listFiles: (sftp, dirName) ->
    deferred = Q.defer()

    sftp.opendir dirName, (err, handle) ->
      if err
        deferred.reject err
      else
        sftp.readdir handle, (err, list) ->
          if err
            deferred.reject err
          else
            if list is false
              deferred.resolve [] # return an empty array
            else
              deferred.resolve list
          sftp.close handle

    deferred.promise

  ###*
   * {@link https://github.com/mscdex/ssh2#stats}
   * Get directory statistics (useful to check if file is directory or file)
   * @param {Object} sftp SFTP handle
   * @param {String} path Path to the file where to get the stats from
   * @return {Promise} A promise, fulfilled with an {Array} or rejected with an error
  ###
  stats: (sftp, path) ->
    d = Q.defer()
    sftp.stat path, (err, stats) ->
      if err
        d.reject err
      else
        d.resolve stats
    d.promise

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
    deferred = Q.defer()

    sftp.fastGet remotePath, localPath, (err) ->
      if err
        deferred.reject err
      else
        deferred.resolve()
    deferred.promise

  ###*
   * Upload a file.
   * @param {Object} sftp SFTP handle
   * @param {String} localPath Upload file to this path
   * @param {String} remotePath Path of the remote file
   * @return {Promise} A promise, fulfilled with an {Object} or rejected with an error
  ###
  putFile: (sftp, localPath, remotePath) ->
    deferred = Q.defer()

    sftp.fastPut localPath, remotePath, (err) ->
      if err
        deferred.reject err
      else
        deferred.resolve()
    deferred.promise

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
    @logger?.debug "About to upload file #{localPath}"
    canUpload = (fileName) =>
      if forceOverwrite
        @logger?.debug 'Force overwrite is true, proceed with upload'
        Q()
      else
        @logger?.debug "Force overwrite is false, checking if #{fileName} exists"
        @stats(sftp, fileName)
        .then (stat) ->
          if stat.isFile()
            Q.reject "Uploading file #{fileName} already exists on the remote server and cannot proceed unless I'm being forced to"
          else
            @logger?.debug "File #{fileName} doesn't appear to be a file, proceeding with upload"
            Q()
        .fail =>
          @logger?.debug "File #{fileName} not found, proceeding with upload"
          Q()

    canUpload(tmpName)
    .then => @putFile(sftp, localPath, tmpName)
    .then =>
      @logger?.debug "File uploaded as #{tmpName}"
      @stats(sftp, tmpName)
    .then (stat) =>
      if stat.isFile()
        # file has been successfully uploaded, move it to correct path
        @logger?.debug "File check successful, about to rename it"
        @safeRenameFile(sftp, tmpName, remotePath)
      else
        # failure, cleanup before rejecting
        @logger?.debug "File check failed, about to cleanup #{tmpName}"
        @removeFile(sftp, tmpName)
        .then -> Q.reject 'File upload check failed'

  ###*
   * Rename a remote resource.
   * @param {Object} sftp SFTP handle
   * @param {String} srcPath Source path of the remote resource
   * @param {String} destPath Destination path of the remote resource
   * @return {Promise} A promise, fulfilled with an {Object} or rejected with an error
  ###
  renameFile: (sftp, srcPath, destPath) ->
    deferred = Q.defer()

    sftp.rename srcPath, destPath, (err) ->
      if err
        deferred.reject err
      else
        deferred.resolve()
    deferred.promise

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
    @logger?.debug "About to safe rename the file #{srcPath} to #{destPath}"
    @stats(sftp, destPath)
    .then (stat) =>
      @logger?.debug "File #{destPath} already exist, about to remove it before rename it"
      if stat.isFile()
        @removeFile(sftp, destPath)
        .then =>
          @logger?.debug "File #{destPath} removed, about to rename it"
          @renameFile(sftp, srcPath, destPath)
          .then -> Q()
          .fail (err) -> Q.reject err
        .fail (err) =>
          # log this message in order to better identify the problem (sftp errors are not that useful)
          # and pass the error to the next handler
          @logger?.debug "Failed to remove file #{destPath} during safeRename"
          Q.reject err
      else
        Q.reject "The resource at #{destPath} already exist and it doesn't appear to be a file. Please check that what you want to rename is a file."
    .fail => @renameFile(sftp, srcPath, destPath)


  ###*
   * Remove remote file
   * @param {Object} sftp SFTP handle
   * @param {String} path Path to the remote file
   * @return {Promise} A promise, fulfilled with an {Array} or rejected with an error
  ###
  removeFile: (sftp, path) ->
    deferred = Q.defer()

    sftp.unlink path, (err) ->
      if err
        deferred.reject err
      else
        deferred.resolve()
    deferred.promise

  ###*
   * Starts a SFTP session.
   * @return {Promise} A promise, fulfilled with an {Object} or rejected with an error
  ###
  openSftp: ->
    deferred = Q.defer()

    @conn = new Connection()
    # TODO: use Logger ?
    @conn.on 'ready', =>
      @logger?.debug 'Connection :: ready'
      @conn.sftp (err, sftp) =>
        if err
          deferred.reject err
        else
          sftp.on 'end', =>
            @logger?.debug 'SFTP :: end'
          deferred.resolve sftp

    @conn.on 'error', (err) =>
      @logger?.debug err, 'Connection :: error'
    @conn.on 'close', (hadError) =>
      @logger?.debug "Connection :: close - had error: #{hadError}"
    @conn.on 'end', =>
      @logger?.debug 'Connection :: end'

    connectOpts =
      host: @_options.host
      username: @_options.username
      password: @_options.password
    if @_options.debug
      connectOpts['debug'] = (msg) => @logger?.debug msg
    @conn.connect connectOpts

    deferred.promise

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
   * @return {Promise} A promise, fulfilled with an {Object} or rejected with an error
  ###
  downloadAllFiles: (sftp, tmpFolder, remoteFolder, fileRegex = '') ->
    deferred = Q.defer()

    @listFiles(sftp, remoteFolder)
    .then (files) =>
      @logger.debug files, 'List of files'
      regex = new RegExp(fileRegex)
      filteredFiles = _.filter files, (f) ->
        switch f.filename
          when '.', '..' then false
          else regex.test(f.filename)
      Q.all _.map filteredFiles, (f) => @stats(sftp, "#{remoteFolder}/#{f.filename}")
      .then (stats) =>
        filesOnly = []
        _.each filteredFiles, (f, i) -> filesOnly.push(f) if stats[i].isFile() # here magic happens!
        @logger.debug filesOnly, "About to download"
        Q.all _.map filesOnly, (f) =>
          @getFile(sftp, "#{remoteFolder}/#{f.filename}", "#{tmpFolder}/#{f.filename}")
      .then -> deferred.resolve()
    .fail (error) -> deferred.reject error

    deferred.promise

module.exports = Sftp

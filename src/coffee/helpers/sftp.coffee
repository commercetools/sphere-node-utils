Q = require 'q'
_ = require 'underscore'
Connection = require 'ssh2'

class Sftp

  constructor: (@_options = {}) ->

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
   * Move/rename a remote resource.
   * @param {Object} sftp SFTP handle
   * @param {String} srcPath Source path of the remote resource
   * @param {String} destPath Destination path of the remote resource
   * @return {Promise} A promise, fulfilled with an {Object} or rejected with an error
  ###
  moveFile: (sftp, srcPath, destPath) ->
    deferred = Q.defer()

    sftp.rename srcPath, destPath, (err) ->
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
      console.log 'Connection :: ready'
      @conn.sftp (err, sftp) ->
        if err
          deferred.reject err
        else
          sftp.on 'end', ->
            console.log 'SFTP :: end'
          deferred.resolve sftp

    @conn.on 'error', (err) ->
      console.log 'Connection :: error - msg: ' + err
    @conn.on 'close', (hadError) ->
      console.log 'Connection :: close - had error: ' + hadError
    @conn.on 'end', ->
      console.log 'Connection :: end'

    @conn.connect
      host: @_options.host
      username: @_options.username
      password: @_options.password

    deferred.promise

  ###*
   * Close SFTP session and underlying connection.
   * @param {Object} sftp SFTP handle
   * @return {Promise} A promise, fulfilled with an {Object} or rejected with an error
  ###
  close: (sftp) ->
    sftp.end() if sftp
    @conn.end()


module.exports = Sftp

Q = require 'q'
_ = require('underscore')._
Connection = require 'ssh2'

class SftpHelpers

  constructor: (options = {}) ->
    @host = options.host
    @username = options.username
    @password = options.password

  ###
  Get directory entries.
  @param {object} sftp SFTP handle.
  @param {string} Directory to get the entries from.
  @return Promise
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
              deferred.resolve [] # return an empty arry
            else
              deferred.resolve list
          sftp.close handle

    deferred.promise

  readFile: (fileName) ->
    # TODO

  saveFile: (path, fileName, content) ->
    # TODO

  ###
  Downloads a file.
  @param {object} sftp SFTP handle.
  @param {string} remotePath Path of the remote file.
  @param {string} localPath Download file to this path.
  @return Promise
  ###
  getFile: (sftp, remotePath, localPath) ->
    deferred = Q.defer()

    sftp.fastGet remotePath, localPath, (err) ->
      if err
        deferred.reject err
      else
        deferred.resolve()
    deferred.promise

  ###
  Starts an SFTP session.
  @return Promise
  ###
  openSftp: ->
    deferred = Q.defer()

    @conn = new Connection()
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
      host: @host
      username: @username
      password: @password

    deferred.promise

  ###
  Close SFTP session and underlying connection.
  @return Promise
  ###
  close: (sftp) ->
    if sftp
      sftp.end()
    @conn.end()


module.exports = SftpHelpers

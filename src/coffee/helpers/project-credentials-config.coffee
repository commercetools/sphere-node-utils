Q = require 'q'
fs = require 'q-io/fs'
{_} = require 'underscore'

_.mixin require('underscore.string')

csv = require 'csv'

###*
 * Provides sphere credentials based on the project key.
 *
 * Following files are used to store the credentials and would be searched (descending priority):
 *
 * ./.sphere-project-credentials
 * ./.sphere-project-credentials.json
 * ~/.sphere-project-credentials
 * ~/.sphere-project-credentials.json
 * /etc/.sphere-project-credentials
 * /etc/.sphere-project-credentials.json
###
class ProjectCredentialsConfig
  @create: (options = {}) ->
    (new ProjectCredentialsConfig(options))._init()

  # private
  constructor: (options = {}) ->
    @_baseName = options.baseName or 'sphere-project-credentials'
    @_lookupFiles = options.lookupFiles or [
      "./.#{@_baseName}"
      "./.#{@_baseName}.json"
      "~/.#{@_baseName}"
      "~/.#{@_baseName}.json"
      "/etc/#{@_baseName}"
      "/etc/#{@_baseName}.json"
    ]

  _init: ->
    @_loadCredentials()
    .then (res) =>
      @_credentials = res
      this

  _loadCredentials: ->
    configsP = _.map @_lookupFiles, (path) =>
      normalizedPath = @_normalizePath path

      fs.exists path
      .then (exists) =>
        if exists
          fs.read path, 'r'
          .then (contents) =>
            if _.endsWith(normalizedPath, ".json")
              @_readJsonConfig "#{contents}"
            else
              @_readCsvConfig "#{contents}"
        else {}

    Q.all(configsP)
    .then (configs) ->
      _.reduce configs.reverse(), ((acc, c) -> _.extend(acc, c)), {}

  _readJsonConfig: (contents) ->
    config = JSON.parse contents

    _.each _.keys(config), (key) ->
      config[key].project_key = key

    Q(config)

  _readCsvConfig: (csvText) ->
    d = Q.defer()

    csv()
    .from(csvText, {delimiter: ":"})
    .to.array (data) ->
      dataJson = _.map data, (row) ->
        {project_key: row[0], client_id: row[1], client_secret: row[2]}

      d.resolve _.reduce dataJson, ((acc, json) -> acc[json.project_key] = json; acc), {}
    .on 'error', (error) ->
      d.reject error

    d.promise

  ###*
   * Returns project credentials for the project key.
   *
   * @param {String} key The project key
   * @returns Credentials have following structure: {project_key: 'key', client_id: 'foo', client_secret: 'bar'}
  ###
  getCredentialsForProjectKey: (key) ->
    @getCredentials
      project_key: key

  ###*
   * Enriches project credentials if client_id or client_secret are missing.
   *
   * @returns Credentials have following structure: {project_key: 'key', client_id: 'foo', client_secret: 'bar'}
  ###
  getCredentials: (credentials) ->
    if credentials.client_id? and credentials.client_secret?
      credentials
    else
      if @_credentials[credentials.project_key]?
        @_credentials[credentials.project_key]
      else
        throw new Error("Can't find credentials for project '#{credentials.project_key}'.")

  _normalizePath: (path) ->
    if not path? or _.isBlank(path)
      throw new Error('Path is empty!')

    path.replace "~", @_getUserHome()

  _getUserHome: ->
    process.env.HOME or process.env.HOMEPATH or process.env.USERPROFILE

exports.ProjectCredentialsConfig = ProjectCredentialsConfig
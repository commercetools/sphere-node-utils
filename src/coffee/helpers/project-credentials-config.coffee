_ = require 'underscore'
_s = require 'underscore.string'
csv = require 'csv'
Promise = require 'bluebird'
fs = Promise.promisifyAll require('fs')

fsExistsAsync = (path) ->
  new Promise (resolve, reject) ->
    fs.exists path, (exists) ->
      if exists
        resolve(true)
      else
        resolve(false)

###*
 * Provides sphere credentials based on the project key.
 *
 * Following files are used to store the credentials and would be searched (descending priority):
 *
 * ./.sphere-project-credentials
 * ./.sphere-project-credentials.json
 * ~/.sphere-project-credentials
 * ~/.sphere-project-credentials.json
 * /etc/sphere-project-credentials
 * /etc/sphere-project-credentials.json
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
      Promise.resolve this

  _loadCredentials: ->
    configsP = _.map @_lookupFiles, (path) =>
      normalizedPath = @_normalizePath path

      fsExistsAsync normalizedPath
      .then (exists) =>
        if exists
          fs.readFileAsync normalizedPath, {encoding: 'utf-8'}
          .then (contents) =>
            if _s.endsWith(normalizedPath, '.json')
              @_readJsonConfig "#{contents}"
            else
              @_readCsvConfig "#{contents}"
        else Promise.resolve {}

    configsP.push(@_getEnvCredetials())

    Promise.all(configsP)
    .then (configs) ->
      _.reduce configs.reverse(), ((acc, c) -> _.extend(acc, c)), {}

  _readJsonConfig: (contents) ->
    config = JSON.parse contents

    _.each _.keys(config), (key) ->
      config[key].project_key = key

    Promise.resolve(config)

  _readCsvConfig: (csvText) ->
    new Promise (resolve, reject) ->
      csv.parse(csvText, {delimiter: ":"}, (data) ->
        dataJson = _.map data, (row) ->
          {project_key: row[0], client_id: row[1], client_secret: row[2]}
        resolve _.reduce dataJson, (acc, json) ->
          acc[json.project_key] = json; acc
        , {})
      .on 'error', (error) -> reject error

  _getEnvCredetials: ->
    envVars = _.pick(
      process.env,
      'SPHERE_PROJECT_KEY', 'SPHERE_CLIENT_ID', 'SPHERE_CLIENT_SECRET'
    )
    if (_.values(envVars).length == 3)
      return {
        "#{envVars.SPHERE_PROJECT_KEY}":
          project_key: envVars.SPHERE_PROJECT_KEY,
          client_id: envVars.SPHERE_CLIENT_ID,
          client_secret: envVars.SPHERE_CLIENT_SECRET
      }

  ###*
   * Returns project credentials for the project key.
   *
   * @param {String} key The project key
   * @returns Credentials have following structure: {project_key: 'key', client_id: 'foo', client_secret: 'bar'}
  ###
  forProjectKey: (key) ->
    @enrichCredentials
      project_key: key

  ###*
   * Enriches project credentials if client_id or client_secret are missing.
   *
   * @returns Credentials have following structure: {project_key: 'key', client_id: 'foo', client_secret: 'bar'}
  ###
  enrichCredentials: (credentials) ->
    if credentials.client_id? and credentials.client_secret?
      credentials
    else
      if @_credentials[credentials.project_key]?
        @_credentials[credentials.project_key]
      else
        throw new Error("Can't find credentials for project '#{credentials.project_key}'.")

  _normalizePath: (path) ->
    if not path? or _s.isBlank(path)
      throw new Error('Path is empty!')

    path.replace "~", @_getUserHome()

  _getUserHome: ->
    process.env.HOME or process.env.HOMEPATH or process.env.USERPROFILE

module.exports = ProjectCredentialsConfig

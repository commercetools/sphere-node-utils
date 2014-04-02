{_} = require 'underscore'
###*
 * Some helpers to deal with the elastic.io platform
###
exports.ElasticIoHelpers =

  getCommonConfig: (cfg) ->
    config =
      client_id: cfg.sphereClientId,
      client_secret: cfg.sphereClientSecret,
      project_key: cfg.sphereProjectKey,
      timeout: cf.timeout or 60000
    # TODO: logentries token

  returnSuccess: (message, next) ->
    next null, message

  returnFailure: (error, message, next) ->
    if not next? and _.isFunction message
      next = message
      message = error.message
    next error, message

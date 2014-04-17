_ = require 'underscore'
Logger = require './logger'

###*
 * Creates a new instance of the ExtendedLogger
 * @class ExtendedLogger
###
module.exports = class

  constructor: (options = {}) ->
    {logConfig, @additionalFields} = _.defaults options,
      additionalFields: {}
    @tmpAdditionalFields = {}
    @bunyanLogger = new Logger logConfig

  _wrapOptions: (type, opts, msg) ->
    if not msg and _.isString opts
      msg = opts
      opts = {}

    _.extend opts, @additionalFields, @tmpAdditionalFields
    @tmpAdditionalFields = {} # reset it
    @bunyanLogger[type](opts, msg)

  withField: (obj) ->
    _.extend @tmpAdditionalFields, obj
    this

  trace: (opts, msg) -> @_wrapOptions 'trace', opts, msg
  debug: (opts, msg) -> @_wrapOptions 'debug', opts, msg
  info: (opts, msg) -> @_wrapOptions 'info', opts, msg
  warn: (opts, msg) -> @_wrapOptions 'warn', opts, msg
  error: (opts, msg) -> @_wrapOptions 'error', opts, msg
  fatal: (opts, msg) -> @_wrapOptions 'fatal', opts, msg

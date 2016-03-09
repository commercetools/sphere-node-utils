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

  _serializeError: (e) ->
    body: e.body
    message: e.message
    name: e.name
    stack: e.stack
    code: e.code
    statusCode: e.statusCode
    signal: e.signal

  _wrapOptions: (type, opts, msg) ->
    if not msg and _.isString opts
      msg = opts
      opts = {}
    # serialize Errors
    if opts instanceof Error
      opts = @_serializeError(opts)
    else if opts?.err instanceof Error # logger.error {err: e}
      opts.err = @_serializeError(opts.err)

    wrappedData =
      data: opts
    _.extend wrappedData, @additionalFields, @tmpAdditionalFields
    @tmpAdditionalFields = {} # reset it
    @bunyanLogger[type](wrappedData, msg)

  withField: (obj) ->
    _.extend @tmpAdditionalFields, obj
    this

  trace: (opts, msg) -> @_wrapOptions 'trace', opts, msg
  debug: (opts, msg) -> @_wrapOptions 'debug', opts, msg
  info: (opts, msg) -> @_wrapOptions 'info', opts, msg
  warn: (opts, msg) -> @_wrapOptions 'warn', opts, msg
  error: (opts, msg) -> @_wrapOptions 'error', opts, msg
  fatal: (opts, msg) -> @_wrapOptions 'fatal', opts, msg

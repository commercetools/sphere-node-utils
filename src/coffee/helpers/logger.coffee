_ = require 'underscore'
bunyan = require 'bunyan'

###*
 * Creates a new instance of the Logger
 * @class Logger
###
module.exports = class

  ###*
   * Describe the logger name
   * @const
   * @type {String}
   * Can be overridden when extending the class
  ###
  @appName: 'sphere-node-utils'

  ###*
   * Set the log level for stout stream. This can be also configured in the constructor options.
   * @const
   * @type {String}
   * @default info
   * Can be overridden when extending the class
  ###
  @levelStream: 'info'

  ###*
   * Set the log level for file stream. This can be also configured in the constructor options.
   * @const
   * @type {String}
   * @default debug
   * Can be overridden when extending the class
  ###
  @levelFile: 'debug'

  ###*
   * Set the path to the log file (in case of file stream). This can be also configured in the constructor options.
   * @const
   * @type {String}
   * Can be overridden when extending the class
  ###
  @path: './sphere-node-utils-debug.log'

  ###*
   * Initialize the Logger with following options:
   * - levelStream: log level for stdout stream 'trace | debug | info | warn | error | fatal' (default 'info')
   * - levelFile: log level for file stream 'trace | debug | info | warn | error | fatal' (default 'debug')
   * - path: the file path where to write the stream (default './log')
   * - logger: a {Bunyan} logger to use instead of creating a new one (usually used from a parent module)
   * - name: the name of the app
   * - serializers: a mapping of log record field name to a serializer function.
   *   By default the {Bunyan} serializers are extended with some custom serializers for {request} objects.
   *   (https://github.com/trentm/node-bunyan#serializers)
   * - src: includes a log of the call source location (file, line, function). Determining the source call
   *   is slow, therefor it's recommended not to enable this on production.
   * - streams: a list of streams that defines the type of output for log messages
   *   (default:
   *     'stream': 'info' -> stdout
   *     'file': 'debug' -> file (path)
   *   )
   * @link https://www.npmjs.org/package/bunyan
   *
   * @constructor
   * @param  {Object} [config] The configuration for the logger
   * @return {Object} A {Bunyan} logger
  ###
  constructor: (config = {}) ->

    {levelStream, levelFile, path, logger, name, serializers, src} = _.defaults config,
      levelStream: @constructor.levelStream
      levelFile: @constructor.levelFile
      path: @constructor.path
      name: @constructor.appName
      serializers: _.extend bunyan.stdSerializers,
        request: @reqSerializer
        response: @resSerializer
      src: false # never use this option on production
    {streams} = _.defaults config,
      streams: [
        {level: levelStream, stream: process.stdout}
        {level: levelFile, path: path}
      ]

    if logger
      logger = logger.child widget_type: @constructor.appName
    else
      logger = bunyan.createLogger
        name: name
        src: src
        serializers: serializers
        streams: streams

    return logger

  ###*
   * A mapping function to serialize objects
   * @param {Object} req The request object
  ###
  reqSerializer: (req) ->
    type: 'REQUEST'
    uri: req.uri
    method: req.method
    headers: req.headers

  ###*
   * A mapping function to serialize objects
   * @param {Object} res The response object
  ###
  resSerializer: (res) ->
    type: 'RESPONSE'
    status: res.statusCode
    headers: res.headers
    body: res.body

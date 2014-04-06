_ = require 'underscore'

###*
 * A collection of methods to be used as underscore mixins
 * @example
 *   _ = require 'underscore'
 *   {_u} = require 'sphere-node-utils'
 *   _.mixin _u
 *
 *   # or
 *   _.mixin require('sphere-node-utils')._u
###
module.exports =

  ###*
   * Returns a deep clone of the given object
   * @param {Object} obj A JSON object
   * @return {Object} A deep clone of the given object
  ###
  deepClone: (obj) ->
    return {} unless obj
    JSON.parse(JSON.stringify(obj))

  ###*
   * Stringifies a JSON object in a pretty format.
   * In case of an error object, the error stack is returned untouched.
   * In case of none of the above, the argument itself is returned.
   * @param {Object} obj A JSON object
   * @param {Number} [indentation] The indentation number (default 2)
   * @return {String} A pretty string
  ###
  prettify: (obj, indentation = 2) ->
    return unless obj
    switch
      when obj instanceof Error then obj.stack
      when _.isObject(obj) then JSON.stringify obj, null, indentation
      else obj

  ###*
   * Returns the percentage of the given values
   * @param {Number} x The current number out of total
   * @param {Number} tot The total number to calculate the percentage
   * @return {Number} The percentage value, rounded
  ###
  percentage: (x, tot) -> Math.round(x * 100 / tot)

  ###*
   * Returns a URL query string from a key-value object
   * @param {Object} params A JSON object containing key-value query params
   * @return {String} A query string, or empty if params is undefined
  ###
  stringifyQuery: (params) ->
    return "" unless params
    query = _.reduce params, (memo, value, key) ->
      memo.push "#{key}=#{value}"
      memo
    , []
    query.join("&")

  ###*
   * Returns a key-value JSON object from a query string
   * @param {String} query A query string
   * @return {Object} A JSON object (note that all values are parsed as string)
  ###
  parseQuery: (query) ->
    return {} unless query
    _.reduce query.split('&'), (memo, param) ->
      splitted = param.split('=')
      return memo if _.size(splitted) < 2
      key = splitted[0]
      value = splitted[1]
      memo[key] = value
      memo
    , {}

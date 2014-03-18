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
   * Returns a URL query string from a key-value object
   * @param {Object} params A JSON object containing key-value query params
   * @retrun {String} A query string, or empty if params is undefined
  ###
  toQueryString: (params) ->
    return "" unless params
    query = _.reduce params, (memo, value, key) ->
      memo.push "#{key}=#{value}"
      memo
    , []
    query.join("&")

  ###*
   * Returns a key-value JSON object from a query string
   * @param {String} query A query string
   * @retrun {Object} A JSON object (note that all values are parsed as string)
  ###
  fromQueryString: (query) ->
    return {} unless query
    _.reduce query.split('&'), (memo, param) ->
      splitted = param.split('=')
      return memo if _.size(splitted) < 2
      key = splitted[0]
      value = splitted[1]
      memo[key] = value
      memo
    , {}

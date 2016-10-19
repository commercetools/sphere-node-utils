debug = require('debug')('repeater')
_ = require 'underscore'
Promise = require 'bluebird'

###*
 * A new Repeater instance
 * @class Repeater
 *
 * A Repeater allows to execute a promise and recover from it in case of errors,
 * by retrying to execute the task for a certain number of times before giving up.
###
class Repeater

  ###*
   * Initialize the class
   * @constructor
   * @param {Object} [options] A JSON object containing configuration options
   * - `attempts` how many times it should retry
   * - `timeout` delay before retrying
   * - `timeoutType`
   *   - `c`: constant delay
   *   - `v`: variable delay (grows with attempts count with a random component)
  ###
  constructor: (options = {}) ->
    @_options = _.defaults options,
      attempts: 10
      timeout: 100
      timeoutType: 'c'
    debug 'new Repeater with options: %j', @_options

  ###*
   * Resolves the {Promise} defined in the `task` function, allowing to
   * recover it from arbitrary errors via the `recover` function.
   * @param  {Promise} task The promise that needs to be resolved
   * @param  {Function} recover A function that is called with the `error` object
   *                            if the `task` promise failed, returning a new {Promise}
   * @return {Promise} A Promise, fulfilled with the resolved `task`, or rejected with an error
  ###
  execute: (task, recover) ->
    new Promise (resolve, reject) =>
      @_repeat
        task: task
        recover: recover
        defer:
          resolve: resolve
          reject: reject
        remainingAttempts: @_options.attempts
        lastError: null

  ###*
   * @private
   * The function that handles the retrying, calling itself recursively
   * @param  {Object} opts The options used for retrying the {Promise}
  ###
  _repeat: (opts) ->
    {task, recover, defer, remainingAttempts, lastError} = opts

    debug '(re)-trying task, %d remaining attempts', remainingAttempts
    if remainingAttempts is 0
      defer.reject
        message: "Failed to retry the task after #{@_options.attempts} attempts."
        error: lastError
    else
      task()
      .then (r) -> defer.resolve r
      .catch (e) =>
        debug 'uh got an error, about to recover: %o', e
        recover e
        .then (newTask) =>
          recoverDelay = @_calculateDelay(remainingAttempts)
          debug 'will recover after %d delay', recoverDelay
          Promise.delay recoverDelay
          .then =>
            debug 'about to recover'
            @_repeat
              task: newTask or task
              recover: recover
              defer: defer
              remainingAttempts: remainingAttempts - 1
              lastError: e
        .catch (e) -> defer.reject e
      .done()

  ###*
   * @private
   * Calculate the delay between attempts based on the `timeoutType`
   * @param  {Number} attemptsLeft How many attempts are left before giving up
   * @return {Number} The calculated delay
  ###
  _calculateDelay: (attemptsLeft) ->
    switch @_options.timeoutType
      when 'v'
        tried = @_options.attempts - attemptsLeft - 1
        tried = 0 if tried < 0
        (@_options.timeout * tried) + _.random(50, @_options.timeout)
      else @_options.timeout

module.exports = Repeater

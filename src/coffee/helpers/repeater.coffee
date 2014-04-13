Q = require 'q'
_ = require 'underscore'

###*
 * Repeater is designed to repeat some arbitrary function unless the execution of this function does not throw any errors
 *
 * Options:
 *   attempts - Int - how many times execution of the function should be repeated until repeater will give up (default 10)
 *   timeout - Long - the delay between attempts
 *   timeoutType - String - The type of the timeout:
 *     'constant' - always the same timeout
 *     'variable' - timeout grows with the attempts count (it also contains random component)
###
class Repeater
  constructor: (options = {}) ->
    @_attempts = if options.attempts? then options.attempts else 10
    @_timeout = if options.timeout? then options.timeout else 100
    @_timeoutType = options.timeoutType or 'variable'

  ###*
   * Executes arbitrary function
   *
   * Options:
   *   task - () => Promise[Any] - the task that should be executed
   *   recoverableError - Error => Boolean - function that decides, whether an error can be recovered by repeating the task execution
  ###
  execute: (options) ->
    throw new Error '`task` function is undefined' unless _.isFunction(options.task)
    throw new Error '`recoverableError` function is undefined' unless _.isFunction(options.recoverableError)

    d = Q.defer()

    @_repeat(@_attempts, options, d, null)

    d.promise

  _repeat: (remainingAttempts, options, defer, lastError) ->
    {task, recoverableError} = options

    if remainingAttempts is 0
      defer.reject new Error("Unsuccessful after #{@_attempts} attempts. Cause: #{lastError.stack}")
    else
      task()
      .then (res) ->
        defer.resolve res
      .fail (e) =>
        if recoverableError(e)
          Q.delay @_calculateDelay(remainingAttempts)
          .then (i) =>
            @_repeat(remainingAttempts - 1, options, defer, e)
        else
          defer.reject e
      .done()

  _calculateDelay: (attemptsLeft) ->
    if @_timeoutType is 'constant'
      @_timeout
    else if @_timeoutType is 'variable'
      tried = @_attempts - attemptsLeft - 1
      (@_timeout * tried) + _.random(50, @_timeout)
    else
      throw new Error("Unsupported timeout type: #{@_timeoutType}")

exports.Repeater = Repeater

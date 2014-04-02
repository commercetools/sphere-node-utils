_ = require 'underscore'
Q = require 'q'

###*
 * Creates a new TaskQueue instance
 * @class TaskQueue
###
class TaskQueue

  ###*
   * Initialize the class
   * @constructor
   * @param {Object} [opts] A JSON object containg configuration options
  ###
  constructor: (opts = {}) ->
    @_options = _.defaults opts,
      maxParallel: 20
    @_queue = []
    @_activeCount = 0

  ###*
   * Add a new Task to the queue
   * @param {Function} taskFn A {Promise} that will be resolved once the task is executed
   * @return {Promise} A promise, fulfilled with an {Object} or rejected with an error
  ###
  addTask: (taskFn) ->
    d = Q.defer()
    @_queue.push {fn: taskFn, defer: d}
    @_maybeExecute()
    d.promise

  ###*
   * Start a task by resolving its {Promise}
   * @param {Object} task A Task object containing a function and a deferred
  ###
  startTask: (task) ->
    @_activeCount += 1

    task.fn()
    .then (res) ->
      task.defer.resolve res
    .fail (error) ->
      task.defer.reject error
    .finally =>
      @_activeCount -= 1
      @_maybeExecute()
    .done()

  ###*
   * @private
   * Will recursively check if a new task should be triggered
  ###
  _maybeExecute: ->
    if @_activeCount < @_options.maxParallel and @_queue.length > 0
      @startTask @_queue.shift()
      @_maybeExecute()

module.exports = TaskQueue

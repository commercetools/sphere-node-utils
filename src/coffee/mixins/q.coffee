Q = require 'q'
_ = require 'underscore'

###*
 * Collection of Q utils
###
module.exports =

  ###*
   * @deprecated Since we moved to {Bluebird} promises, this is not needed anymore and
   * this is just for backwards compatibility.
   *
   * Process each element in the given list using the function fn (called on each iteration).
   * The function fn has to return a promise that should be resolved when all elements of the page are processed.
   * @param {Array} list A list of elements to process
   * @param {Function} fn The function to process a page that returns a promise
   * @param {Object} [options] Optional parameters to configure the process
   * - `maxParallel` (default 1) defines how many elements from the list will be passed to the process function
   * - `accumulate` (default true) whether to accumulate or not all results to be returned at the end
   * @throws {Error} If arguments are not correct
   * @return {Promise} A promise, fulfilled with an array of the resolved results of function fn or the rejected result of fn
   * @example
   *   list = [{key: '1'}, {key: '2'}, {key: '3'}]
   *   processList list, (elems) ->
   *     doSomethingWith(elems) # it's a promise
   *     .then ->
   *       # something else
   *       anotherPromise().then -> Q('OK')
   *   .then (results) -> # results will be an array ['OK', 'OK', 'OK']
  ###
  processList: (list, fn, options = {}) ->
    throw new Error 'Please provide a function to process the list' unless _.isFunction fn
    d = Q.defer()
    {maxParallel, accumulate} = _.defaults options,
      maxParallel: 1
      accumulate: true
    throw new Error 'MaxParallel must be a number >= 1' if maxParallel < 1
    acc = []
    _process = (tickList) ->
      if _.isEmpty(tickList)
        d.resolve(acc)
      else
        elements = _.head tickList, maxParallel
        tail = _.tail tickList, maxParallel
        fn(elements)
        .then (result) ->
          acc.push(result) if accumulate
          _process(tail)
        .fail (error) -> d.reject error
        .done()
    _process(list)
    d.promise

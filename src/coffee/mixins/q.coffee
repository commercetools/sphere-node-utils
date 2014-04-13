Q = require 'q'
_ = require 'underscore'

###*
 * Collection of Q utils
###
module.exports =

  ###*
   * Process each element in the given list using the function fn (called on each iteration).
   * The function fn has to return a promise that should be resolved when all elements of the page are processed.
   * @param {Array} list A list of elements to process
   * @param {Function} fn The function to process a page that returns a promise
   * @throws {Error} If arguments are not correct
   * @return {Promise} A promise, fulfilled with an array of the resolved results of function fn or the rejected result of fn
   * @example
   *   list = [{key: '1'}, {key: '2'}, {key: '3'}]
   *   processList list, (elem) ->
   *     doSomethingWith(elem) # it's a promise
   *     .then ->
   *       # something else
   *       anotherPromise()
  ###
  processList: (list, fn) ->
    throw new Error 'Please provide a function to process the list' unless _.isFunction fn
    d = Q.defer()
    _process = (tick) ->
      if tick >= list.length
        d.resolve()
      else
        elem = list[tick]
        fn(elem)
        .then -> _process(tick + 1)
        .fail (error) -> d.reject error
        .done()
    _process(0)
    d.promise

Q = require 'q'
_ = require 'underscore'
_.mixin percentage: (x, tot) -> Math.round(x * 100 / tot)

MAX_PAGED_LIMIT = 50

module.exports =

  ###*
   * Process promises in batches using a recursive function.
   * Supports promise subscription of progress notifications.
   *
   * @param {Array} promises A list of promises
   * @param {Number} limit Number of parallel requests to be sent in batch
   * @return {Promise} A promise, fulfilled with an {Array} of results or rejected with an error
   * @example
   * 1) simple batch process
   *   allPromises = [p1, p2, p3, ...]
   *   batch(allPromises)
   *   .then (results) ->
   *   .fail (error) ->
   *
   * 2) batch process with custom limit
   *   allPromises = [p1, p2, p3, ...]
   *   batch(allPromises, 30)
   *   .then (results) ->
   *   .fail (error) ->
   *
   * 3) batch process with notification subscription
   *   allPromises = [p1, p2, p3, ...]
   *   batch(allPromises)
   *   .then (results) ->
   *   .progress (progress) -> console.log "#{progress.percentage}% processed"
   *   .fail (error) ->
  ###
  all: (promises, limit = 50) ->
    # TODO: define a hard limit?
    deferred = Q.defer()
    totalPromises = _.size(promises)

    _processInBatches = (currentPromises, limit, accumulator = []) ->
      head = _.head currentPromises, limit
      # TODO: use `allSettled` ?
      Q.all(head).then (results) ->
        # notify any handler registered to the promise with
        # the progress percentage and the current results
        deferred.notify
          percentage: _.percentage(totalPromises - _.size(currentPromises), totalPromises)
          value: results

        allResults = _.union accumulator, results
        if _.size(head) < limit
          # return if there are no more batches
          deferred.resolve allResults
        else
          tail = _.tail currentPromises, limit
          _processInBatches tail, limit, allResults
      .fail (err) -> deferred.reject err
    _processInBatches(promises, limit)

    deferred.promise


  ###*
   * Fetch all results of a Sphere resource query endpoint in batches of pages using a recursive function.
   * Supports promise subscription of progress notifications.
   *
   * @param {Rest} rest An instance of the Rest client (sphere-node-connect)
   * @param {String} endpoint The resource endpoint to be queried
   * @param {Object} params Sphere query parameters by key {staged: true, where: '...'}. Limit should be 0 if set. Offset is always 0.
   * @return {Promise} A promise, fulfilled with an {Object} of {PagedQueryResponse} or rejected with an error
  ###
  paged: (rest, endpoint, params = {}) ->
    deferred = Q.defer()

    # TODO: throws if limit is not 0 (it wouldn't make sense to use this function if there is a limit) ?
    params = _.extend {}, params,
      limit: MAX_PAGED_LIMIT
      offset: 0
    limit = params.limit

    _toQueryString = (offset) ->
      extended = _.extend {}, params,
        offset: offset
      query = _.reduce extended, (memo, value, key) ->
        memo.push "#{key}=#{value}"
        memo
      , []
      query.join("&")

    _buildPagedQueryResponse = (results) ->
      tot = _.size(results)

      offset: params.offset
      count: tot
      total: tot
      results: results

    _page = (offset, total, accumulator = []) ->
      if total? and (offset + limit) >= total + limit
        deferred.notify
          percentage: 100
          value: accumulator
        # return if there are no more pages
        deferred.resolve _buildPagedQueryResponse(accumulator)
      else
        queryParams = _toQueryString(offset)
        rest.GET "#{endpoint}?#{queryParams}", (error, response, body) ->
          deferred.notify
            percentage: if total then _.percentage(total - (offset + limit), total) else 0
            value: accumulator
          if error
            deferred.reject error
          else
            if response.statusCode is 200
              _page(offset + limit, body.total, accumulator.concat(body.results))
            else
              deferred.reject body
    _page(params.offset)

    deferred.promise

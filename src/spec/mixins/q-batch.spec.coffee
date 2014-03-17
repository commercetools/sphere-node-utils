Q = require 'q'
_ = require 'underscore'
{Rest} = require 'sphere-node-connect'
ApiConfig = require('../../config').config.api
Qbatch = require '../../lib/mixins/q-batch'

describe 'Mixins', ->

  describe 'Qbatch :: all', ->

    createPromise = (index) ->
      d = Q.defer()
      count = 0
      interval = setInterval ->
        count += 20
        if count is 100
          d.resolve {id: index, value: count}
          clearInterval(interval)
      , 200
      d.promise

    beforeEach ->
      @allPromises = _.map [1..1000], (i) -> createPromise(i)

    it 'should process in batches', (done) ->
      Qbatch.all(@allPromises)
      .then (results) ->
        expect(results.length).toBe 1000
        done()
      .fail (err) -> done(err)

    it 'should subscribe to promise notifications', (done) ->
      expectedProgress = 0
      Qbatch.all(@allPromises)
      .progress (progress) ->
        expect(progress.percentage).toBe expectedProgress
        expectedProgress += 5 # total is 1000 and limit is 50, so each progress is incremented by 5
      .fail (err) -> done(err)
      .done -> done()

    it 'should process in batches with given limit', (done) ->
      expectedProgress = 0
      Qbatch.all(@allPromises, 10)
      .then (results) ->
        expect(results.length).toBe 1000
        done()
      .progress (progress) ->
        expect(progress.percentage).toBe expectedProgress
        expectedProgress += 1
      .fail (err) -> done(err)


  describe 'Qbatch :: paged', ->

    beforeEach ->
      @rest = new Rest config: ApiConfig

    it 'should fetch products in batches', (done) ->
      spyOn(@rest, 'GET').andCallFake (endpoint, callback) -> callback null, {statusCode: 200},
        total: 1000
        results: _.map [1..50], (i) -> {id: _.uniqueId("_#{i}"), value: 'foo'}

      Qbatch.paged(@rest, '/product-projections')
      .then (products) ->
        expect(products.total).toBe 1000
        expect(products.count).toBe 1000
        expect(products.offset).toBe 0
        expect(products.results.length).toBe 1000
        done()
      .fail (err) -> done(err)

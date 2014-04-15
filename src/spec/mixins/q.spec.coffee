Q = require 'q'
_ = require 'underscore'
_.mixin require '../../lib/mixins/underscore'
Qutils = require '../../lib/mixins/q'

describe 'Qutils', ->

  it 'should process a list of elements sequentially', (done) ->
    Qutils.processList [1..5], (i) -> Q(i)
    .then (results) ->
      expect(results).toEqual [1, 2, 3, 4, 5]
      done()
    .fail (error) -> done _.prettify error

  it 'should reject if processed promise fails', (done) ->
    Qutils.processList [1..5], (i) -> Q.reject('Oops')
    .then -> done('Should not happen')
    .fail (error) ->
      expect(error).toBe 'Oops'
      done()

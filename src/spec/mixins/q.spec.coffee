Q = require 'q'
_ = require 'underscore'
{Qutils} = require '../../lib/main'

describe 'Qutils', ->

  it 'should process a list of elements sequentially', (done) ->
    count = 1
    Qutils.processList [1..5], (i) ->
      expect(_.isArray(i)).toBe true
      expect(i.length).toBe 1
      Q(count++)
    .then (results) ->
      expect(results).toEqual [1, 2, 3, 4, 5]
      done()
    .fail (error) -> done error

  it 'should process a list of elements sequentially (maxParallel 5)', (done) ->
    count = 1
    Qutils.processList [1..10], (i) ->
      expect(_.isArray(i)).toBe true
      expect(i.length).toBe 5
      Q(count++)
    , {maxParallel: 5}
    .then (results) ->
      expect(results).toEqual [1, 2]
      done()
    .fail (error) -> done error

  it 'should process a list of elements sequentially (accumulate false)', (done) ->
    count = 1
    Qutils.processList [1..5], (i) ->
      expect(_.isArray(i)).toBe true
      expect(i.length).toBe 1
      Q(count++)
    , {accumulate: false}
    .then (results) ->
      expect(results).toEqual []
      done()
    .fail (error) -> done error

  it 'should reject if processed promise fails', (done) ->
    Qutils.processList [1..5], (i) -> Q.reject('Oops')
    .then -> done('Should not happen')
    .fail (error) ->
      expect(error).toBe 'Oops'
      done()

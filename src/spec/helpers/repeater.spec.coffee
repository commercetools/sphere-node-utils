Q = require 'q'
_ = require 'underscore'
_.mixin require('underscore.string').exports()

{Repeater} = require '../../lib/helpers/repeater'

describe 'Repeater', ->
  it 'should repeat task until it returns some successful result', (done) ->
    repeated = 0

    new Repeater
      attempts: 10
      timeout: 0
    .execute
      recoverableError: (e) -> e.message is 'foo'
      task: ->
        repeated += 1

        if repeated < 3
          Q.reject(new Error('foo'))
        else
          Q("Success")
    .then (res) ->
      expect(repeated).toEqual 3
      expect(res).toEqual "Success"
      done()
    .fail (error) ->
      done(error)

  it 'should boubble up unrecoverable errors', (done) ->
    repeated = 0

    new Repeater
      attempts: 10
      timeout: 0
    .execute
      recoverableError: (e) -> e.message is 'foo'
      task: ->
        repeated += 1

        if repeated < 3
          Q.reject(new Error('foo'))
        else if repeated is 3
          Q.reject(new Error('baz'))
        else
          Q("Success")
    .then (res) ->
      done("Error was not produced.")
    .fail (error) ->
      expect(repeated).toEqual 3
      expect(error.message).toEqual "baz"
      done()

  it 'should boubble up an error after provided number of attempts', (done) ->
    repeated = 0

    new Repeater
      attempts: 3
      timeout: 0
    .execute
      recoverableError: (e) -> e.message is 'foo'
      task: ->
        repeated += 1
        Q.reject(new Error('foo'))
    .then (res) ->
      done("Error was not produced.")
    .fail (error) ->
      expect(repeated).toEqual 3
      expect(_.startsWith(error.message, 'Unsuccessful after 3 attempts')).toBe true
      done()
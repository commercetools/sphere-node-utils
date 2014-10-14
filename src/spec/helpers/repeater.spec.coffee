_ = require 'underscore'
_.mixin require('underscore.string').exports()
Promise = require 'bluebird'
{Repeater} = require '../../lib/main'

describe 'Repeater', ->

  it 'should repeat task until it returns some successful result', (done) ->
    repeated = 0

    new Repeater()
    .execute ->
      repeated += 1
      if repeated < 5
        Promise.reject new Error('foo')
      else
        Promise.resolve 'success'
    , (e) ->
      if e.message is 'foo'
        Promise.resolve()
      else
        Promise.reject 'It should have been resolved'
    .then (res) ->
      expect(repeated).toEqual 5
      expect(res).toEqual "success"
      done()
    .catch (error) -> done(error)

  it 'should recover with a new task', (done) ->
    repeated = 0
    task = new Promise (resolve, reject) ->
      setTimeout ->
        reject new Error('foo') # make sure it will recover
      , 100

    new Repeater()
    .execute ->
      task
    , (e) ->
      repeated += 1
      if e.message is 'foo'
        Promise.resolve ->
          new Promise (resolve, reject) ->
            setTimeout ->
              if repeated is 5
                resolve 'success'
              else
                reject new Error('foo')
            , 100
      else
        Promise.reject 'It should have been resolved'
    .then (res) ->
      expect(repeated).toEqual 5
      expect(res).toEqual "success"
      done()
    .catch (error) -> done(error)

  it 'should boubble up unrecoverable errors', (done) ->
    repeated = 0

    new Repeater()
    .execute ->
      repeated += 1
      switch
        when repeated < 5 then Promise.reject new Error('foo')
        when repeated is 5 then Promise.reject new Error('bar')
        else Promise.resolve 'success'
    , (e) ->
      if e.message is 'foo'
        Promise.resolve()
      else
        Promise.reject "It should error with bar: #{e.message}"
    .then -> done 'It should have failed'
    .catch (error) ->
      expect(repeated).toEqual 5
      expect(error).toBe 'It should error with bar: bar'
      done()

  it 'should boubble up an error after using all attempts', (done) ->
    repeated = 0

    new Repeater attempts: 3
    .execute ->
      repeated += 1
      Promise.reject new Error('foo')
    , (e) -> Promise.resolve()
    .then -> done 'It should have failed'
    .catch (error) ->
      expect(repeated).toEqual 3
      expect(_.startsWith(error.message, 'Failed to retry the task after 3 attempts')).toBe true
      done()

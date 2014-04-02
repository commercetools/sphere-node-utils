{ElasticIoHelpers} = require '../../lib/helpers/elasticio'

describe 'Elasticio', ->

  it 'should call next with success message', (done) ->
    ElasticIoHelpers.returnSuccess 'Works!', (error, message) ->
      expect(error).toBe null
      expect(message).toBe 'Works!'
      done()

  it 'should call next with error and message', (done) ->
    ElasticIoHelpers.returnFailure new Error('shit happens'), 'not so goood', (error, message) ->
      expect(error).toEqual new Error('shit happens')
      expect(message).toBe 'not so goood'
      done()

  it 'should call next with error', (done) ->
    ElasticIoHelpers.returnFailure new Error('oh oh'), (error, message) ->
      expect(error).toEqual new Error('oh oh')
      expect(message).toBe 'oh oh'
      done()

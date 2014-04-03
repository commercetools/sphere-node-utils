{ElasticIo} = require '../../lib/helpers/elasticio'

describe 'Elasticio', ->

  it 'should call next with success message', (done) ->
    ElasticIo.returnSuccess 'Works!', (error, message) ->
      expect(error).toBe null
      expect(message).toBe 'Works!'
      done()

  it 'should call next with error and message', (done) ->
    ElasticIo.returnFailure new Error('shit happens'), 'not so goood', (error, message) ->
      expect(error).toEqual new Error('shit happens')
      expect(message).toBe 'not so goood'
      done()

  it 'should call next with error', (done) ->
    ElasticIo.returnFailure new Error('oh oh'), (error, message) ->
      expect(error).toEqual new Error('oh oh')
      expect(message).toBe 'oh oh'
      done()

  it 'should extract config', ->
    cfg =
      foo: 'bar'
    config = ElasticIo.getCommonConfig cfg
    expectedConfig =
      client_id: undefined
      client_secret: undefined
      project_key: undefined
      timeout: 60000
    expect(config).toEqual expectedConfig

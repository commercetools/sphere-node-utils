_ = require 'underscore'
{ExtendedLogger} = require '../../lib/main'

describe 'ExtendedLogger', ->

  beforeEach ->
    @log = new ExtendedLogger
      additionalFields:
        project_key: 'foo'
        another_field: 'bar'

  it 'should initialize with default options', ->
    log = new ExtendedLogger()

    expect(log.additionalFields).toEqual {}
    expect(log.bunyanLogger).toBeDefined()

  it 'should initialize with custom options', ->
    expect(@log.additionalFields).toEqual
      project_key: 'foo'
      another_field: 'bar'
    expect(@log.bunyanLogger).toBeDefined()

  describe ':: wrapper', ->

    _.each ['trace', 'debug', 'info', 'warn', 'error', 'fatal'], (level) ->
      it "should log (#{level}) with extended object and message", ->
        spyOn(@log.bunyanLogger, level)
        @log[level] {id: 123}, 'Hello'
        expect(@log.bunyanLogger[level]).toHaveBeenCalledWith {data: {id: 123}, project_key: 'foo', another_field: 'bar'}, 'Hello'

      it "should log (#{level}) with additional fields and message", ->
        spyOn(@log.bunyanLogger, level)
        @log[level] 'Hello'
        expect(@log.bunyanLogger[level]).toHaveBeenCalledWith {data: {}, project_key: 'foo', another_field: 'bar'}, 'Hello'

      it "should log (#{level}) with extended object and no message", ->
        spyOn(@log.bunyanLogger, level)
        @log[level] {id: 123}
        expect(@log.bunyanLogger[level]).toHaveBeenCalledWith {data: {id: 123}, project_key: 'foo', another_field: 'bar'}, undefined

      it "should log (#{level}) with extended object and string", ->
        spyOn(@log.bunyanLogger, level)
        @log[level] 'Some message', 'Oops, something went wrong'
        expect(@log.bunyanLogger[level]).toHaveBeenCalledWith {data: 'Some message', project_key: 'foo', another_field: 'bar'}, 'Oops, something went wrong'

  describe ':: withField', ->

    _.each ['trace', 'debug', 'info', 'warn', 'error', 'fatal'], (level) ->
      it "should chain field (#{level}) for extended object", ->
        spyOn(@log.bunyanLogger, level)
        @log.withField(token: 'qwerty')[level] {id: 123}, 'Hello'
        expect(@log.bunyanLogger[level]).toHaveBeenCalledWith {data: {id: 123}, project_key: 'foo', another_field: 'bar', token: 'qwerty'}, 'Hello'

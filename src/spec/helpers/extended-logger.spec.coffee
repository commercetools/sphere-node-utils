ExtendedLogger = require '../../lib/helpers/extended-logger'

describe 'ExtendedLogger', ->

  it 'should initialize with default options', ->
    log = new ExtendedLogger()

    expect(log.additionalFields).toEqual {}
    expect(log.bunyanLogger).toBeDefined()

  it 'should initialize with custom options', ->
    log = new ExtendedLogger
      additionalFields:
        project_key: 'foo'
        another_field: 'bar'

    expect(log.additionalFields).toEqual
      project_key: 'foo'
      another_field: 'bar'
    expect(log.bunyanLogger).toBeDefined()

  describe ':: wrapper', ->

    beforeEach ->
      @log = new ExtendedLogger
        additionalFields:
          project_key: 'foo'
          another_field: 'bar'

    it 'should log with extended object and message', ->
      spyOn(@log.bunyanLogger, 'info')
      @log.info {id: 123}, 'Hello'
      expect(@log.bunyanLogger.info).toHaveBeenCalledWith {id: 123, project_key: 'foo', another_field: 'bar'}, 'Hello'

    it 'should log with additional fields and message', ->
      spyOn(@log.bunyanLogger, 'info')
      @log.info 'Hello'
      expect(@log.bunyanLogger.info).toHaveBeenCalledWith {project_key: 'foo', another_field: 'bar'}, 'Hello'

    it 'should log with extended object and no message', ->
      spyOn(@log.bunyanLogger, 'info')
      @log.info {id: 123}
      expect(@log.bunyanLogger.info).toHaveBeenCalledWith {id: 123, project_key: 'foo', another_field: 'bar'}, undefined

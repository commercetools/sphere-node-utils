Logger = require '../../lib/helpers/logger'

class MyLogger extends Logger
  @appName: 'foo'
  @path: './foo-test.log'

describe 'Logger', ->

  it 'should initialize with default options', ->
    log = new Logger()

    expect(log.streams[0].type).toBe 'stream'
    expect(log.streams[0].level).toBe 30 # info
    expect(log.streams[1].type).toBe 'file'
    expect(log.streams[1].level).toBe 20 # debug
    expect(log.streams[1].path).toBe './sphere-node-utils-debug.log'
    expect(log.fields.name).toBe 'sphere-node-utils'
    expect(log.serializers.request).toEqual jasmine.any(Function)
    expect(log.serializers.response).toEqual jasmine.any(Function)
    expect(log.src).toBe false

  it 'should initialize with custom options', ->
    log = new Logger
      levelStream: 'error'
      levelFile: 'trace'
      path: './another-path.log'
      name: 'foo'
      serializers: foo: -> 'bar'
      src: true
      streams: [
        {level: 'warn', stream: process.stdout}
      ]

    expect(log.streams[0].type).toBe 'stream'
    expect(log.streams[0].level).toBe 40 # warn
    expect(log.streams[1]).not.toBeDefined()
    expect(log.fields.name).toBe 'foo'
    expect(log.serializers.foo()).toBe 'bar'
    expect(log.src).toBe true

  it 'should initialize with empty streams', ->
    log = new Logger
      streams: []

    expect(log.streams.length).toBe 0
    expect(log.streams[0]).not.toBeDefined()

  it 'should use given logger', ->
    existingLogger = new MyLogger()
    log = new Logger logger: existingLogger

    expect(log.fields.name).toBe 'foo'
    expect(log.streams[1].path).toBe './foo-test.log'
    expect(log.fields.widget_type).toBe 'sphere-node-utils'

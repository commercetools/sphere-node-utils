{Logger, ExtendedLogger, TaskQueue, Sftp, ProjectCredentialsConfig, Repeater, ElasticIo, Qutils} = require '../lib/main'

describe 'exports', ->

  it 'Logger', -> expect(Logger).toBeDefined()

  it 'ExtendedLogger', -> expect(ExtendedLogger).toBeDefined()

  it 'TaskQueue', -> expect(TaskQueue).toBeDefined()

  it 'Sftp', -> expect(Sftp).toBeDefined()

  it 'ProjectCredentialsConfig', -> expect(ProjectCredentialsConfig).toBeDefined()

  it 'Repeater', -> expect(Repeater).toBeDefined()

  it 'ElasticIo', -> expect(ElasticIo).toBeDefined()

  it 'Qutils', -> expect(Qutils).toBeDefined()

{Logger, TaskQueue, Sftp, ProjectCredentialsConfig, ElasticIo, Qbatch, _u} = require '../lib/main'

describe 'exports', ->

  it 'Logger', -> expect(Logger).toBeDefined()

  it 'TaskQueue', -> expect(TaskQueue).toBeDefined()

  it 'Sftp', -> expect(Sftp).toBeDefined()

  it 'ProjectCredentialsConfig', -> expect(ProjectCredentialsConfig).toBeDefined()

  it 'ElasticIo', -> expect(ElasticIo).toBeDefined()

  it 'Qbatch', -> expect(Qbatch).toBeDefined()

  it '_u', -> expect(_u).toBeDefined()

{Sftp, Qbatch, _u} = require '../lib/main'

describe "exports", ->

  it "Sftp", ->
    expect(Sftp).toBeDefined()

  it "Qbatch", ->
    expect(Qbatch).toBeDefined()

  it "_u", ->
    expect(_u).toBeDefined()
Q = require 'q'
TaskQueue = require '../../lib/helpers/task-queue'

describe 'TaskQueue', ->

  beforeEach ->
    @task = new TaskQueue

  it 'should define default values', ->
    expect(@task._options).toEqual
      maxParallel: 20
    expect(@task._queue).toEqual []
    expect(@task._activeCount).toBe 0

  it 'should pass custom options', ->
    task = new TaskQueue maxParallel: 50
    expect(task._options).toEqual
      maxParallel: 50

  it 'should add a task to the queue and return a promise', ->
    spyOn(@task, '_maybeExecute')
    promise = @task.addTask Q()
    expect(Q.isPromise(promise)).toBe true
    expect(@task._queue.length).toBe 1
    expect(@task._maybeExecute).toHaveBeenCalled()

  it 'should start and resolve a task', (done) ->
    callMe = ->
      d = Q.defer()
      setTimeout ->
        d.resolve true
      , 500
      d.promise
    @task.addTask callMe
    .then (result) ->
      expect(result).toBe true
      done()
    .fail (error) -> done(error)

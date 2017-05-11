Promise = require 'bluebird'
{TaskQueue} = require '../../lib/main'

describe 'TaskQueue', ->

  beforeEach ->
    @task = new TaskQueue

  it 'should define default values', ->
    expect(@task._maxParallel).toBe 20
    expect(@task._queue).toEqual []
    expect(@task._activeCount).toBe 0

  it 'should pass custom options', ->
    task = new TaskQueue maxParallel: 50
    expect(task._maxParallel).toBe 50

  it 'should set maxParallel', ->
    @task.setMaxParallel 10
    expect(@task._maxParallel).toBe 10

  it 'should throw if maxParallel is < 1', ->
    expect(=> @task.setMaxParallel(0)).toThrow new Error 'MaxParallel must be a number between 1 and 100'

  it 'should throw if maxParallel is > 100', ->
    expect(=> @task.setMaxParallel(101)).toThrow new Error 'MaxParallel must be a number between 1 and 100'

  it 'should add a task to the queue and return a promise', ->
    spyOn(@task, '_maybeExecute')
    promise = @task.addTask Promise.resolve()
    expect(promise.isPending()).toBe true
    expect(@task._queue.length).toBe 1
    expect(@task._maybeExecute).toHaveBeenCalled()

  it 'should start and resolve a task', (done) ->
    callMe = ->
      new Promise (resolve, reject) ->
        setTimeout ->
          resolve true
        , 500
    @task.addTask callMe
    .then (result) ->
      expect(result).toBe true
      done()
    .catch (error) -> done(error)

  it 'should execute and finish all tasks', (done) ->
    expectedExecutionOrder = [1, 2, 20, 3, 4]
    actualExecutionOrder = []
    actualFinishedTasks = []
    @task.setMaxParallel 2

    callMe = (input) ->
      new Promise (resolve) ->
        actualExecutionOrder.push(input)
        setTimeout ->
          actualFinishedTasks.push(input)
          resolve input
        , 100 * input

    taskPromise = null

    expectedExecutionOrder.forEach((input, i) =>
      taskPromise = @task.addTask(callMe.bind(this, input))
        .then (result) ->
          expect(result).toBe(expectedExecutionOrder[i])
    )

    taskPromise
      .then () ->
        expect(actualExecutionOrder).toEqual(expectedExecutionOrder)
        expect(actualFinishedTasks.length).toBe(5)
        done()
      .catch (error) -> done(error)

  it 'should reject all when one promise fails', (done) ->
    callMeResolve = () ->
      new Promise (resolve) ->
        setTimeout ->
          resolve()
        , 500

    callMeReject = () ->
      new Promise (resolve, reject) ->
        setTimeout ->
          reject()
        , 500

    @task.addTask callMeResolve
    taskPromise = @task.addTask callMeReject

    taskPromise
      .then () ->
        done('Should fail')
      .catch () ->
        done()
_ = require 'underscore'
Promise = require 'bluebird'
{ProjectCredentialsConfig} = require '../../lib/main'

describe 'ProjectCredentialsConfig', ->

  it 'should correctly parse configuration files and override credentials correctly', (done) ->
    ProjectCredentialsConfig.create
      lookupFiles: ['data/config/config3', 'data/config/config2.json', 'data/config/does-not-exists', 'data/config/config1']
    .then (config) ->
      expect(config.forProjectKey('project-a')).toEqual
        project_key: 'project-a'
        client_id: 'clientId1'
        client_secret: 'clientSecret1'

      expect(config.enrichCredentials({project_key: 'project-b'})).toEqual
        project_key: 'project-b'
        client_id: 'clientId3'
        client_secret: 'clientSecret3'

      expect(config.forProjectKey('project-c')).toEqual
        project_key: 'project-c'
        client_id: 'clientId5'
        client_secret: 'clientSecret5'

      expect(config.forProjectKey('project-d')).toEqual
        project_key: 'project-d'
        client_id: 'clientId6'
        client_secret: 'clientSecret6'

      expect(config.forProjectKey('project-z')).toEqual
        project_key: 'project-z'
        client_id: 'clientId100:foooo'
        client_secret: 'clientSecret100'

      expect(config.enrichCredentials({project_key: 'foo', client_id: "foo1", client_secret: "foo2"})).toEqual
        project_key: 'foo'
        client_id: 'foo1'
        client_secret: 'foo2'
      done()
    .catch (error) -> done(error)
    .done()

  it "should load credentials from environment variables", (done) ->
    process.env.SPHERE_PROJECT_KEY = 'project-key'
    process.env.SPHERE_CLIENT_ID = 'client-id'
    process.env.SPHERE_CLIENT_SECRET = 'client-secret'

    ProjectCredentialsConfig.create()
    .then (config) ->
      actual = config.forProjectKey('project-key')
      expected = {
        project_key: 'project-key'
        client_id: 'client-id'
        client_secret: 'client-secret'
      }
      expect(actual).toEqual(expected)
      done()
    .catch (err) -> done(err)

  it "should throw an error if credentials are not defined", (done) ->
    ProjectCredentialsConfig.create
      lookupFiles: ['data/config/config3']
    .then (config) ->
      expect(-> config.forProjectKey('non-existing-project')).toThrow new Error "Can't find credentials for project 'non-existing-project'."
      done()
    .catch (error) -> done(error)
    .done()

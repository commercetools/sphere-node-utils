Q = require 'q'
_ = require 'underscore'
ProjectCredentialsConfig = require '../../lib/helpers/project-credentials-config'

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
    .fail (error) ->
      done(error)
    .done()

  it "should throw an error if credentials are not defined", (done) ->
    ProjectCredentialsConfig.create
      lookupFiles: ['data/config/config3']
    .then (config) ->
      expect(-> config.forProjectKey('non-existing-project')).toThrow new Error "Can't find credentials for project 'non-existing-project'."
      done()
    .fail (error) ->
      done(error)
    .done()

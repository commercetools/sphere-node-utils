![SPHERE.IO icon](https://admin.sphere.io/assets/images/sphere_logo_rgb_long.png)

# Node.js Utils

[![NPM](https://nodei.co/npm/sphere-node-utils.png?downloads=true)](https://www.npmjs.org/package/sphere-node-utils)

[![Build Status](https://secure.travis-ci.org/sphereio/sphere-node-utils.png?branch=master)](http://travis-ci.org/sphereio/sphere-node-utils) [![NPM version](https://badge.fury.io/js/sphere-node-utils.png)](http://badge.fury.io/js/sphere-node-utils) [![Coverage Status](https://coveralls.io/repos/sphereio/sphere-node-utils/badge.png)](https://coveralls.io/r/sphereio/sphere-node-utils) [![Dependency Status](https://david-dm.org/sphereio/sphere-node-utils.png?theme=shields.io)](https://david-dm.org/sphereio/sphere-node-utils) [![devDependency Status](https://david-dm.org/sphereio/sphere-node-utils/dev-status.png?theme=shields.io)](https://david-dm.org/sphereio/sphere-node-utils#info=devDependencies)

This module shares helpers among all [SPHERE.IO](http://sphere.io/) Node.js components.

## Table of Contents
* [Getting Started](#getting-started)
* [Documentation](#documentation)
  * [Helpers](#helpers)
    * [Logger](#logger)
    * [ExtendedLogger](#extendedlogger)
    * [TaskQueue](#taskqueue)
    * [Sftp](#sftp)
    * [ProjectCredentialsConfig](#projectcredentialsconfig)
    * [Repeater](#repeater)
    * [ElasticIo](#elasticio)
    * [UserAgent](#useragent)
  * [Mixins](#mixins)
    * [Qutils](#qutils)
* [Examples](#examples)
* [Releasing](#releasing)
* [License](#license)


## Getting Started

```coffeescript
SphereUtils = require 'sphere-node-utils'
Logger = SphereUtils.Logger
TaskQueue = SphereUtils.TaskQueue
...

# or
{Logger, TaskQueue, ...} = require 'sphere-node-utils'
```

## Documentation

### Helpers
Currently following helpers are provided by `SphereUtils`:

- `Logger`
- `ExtendedLogger`
- `TaskQueue`
- `Sftp`
- `ProjectCredentialsConfig`
- `ElasticIo`
- `userAgent`
- `Repeater`

#### Logger
Logging is supported by the lightweight JSON logging module called [Bunyan](https://github.com/trentm/node-bunyan).

The `Logger` can be configured with following options
```coffeescript
logConfig:
  levelStream: 'info' # log level for stdout stream
  levelFile: 'debug' # log level for file stream
  path: './sphere-node-utils-debug.log' # where to write the file stream
  name: 'sphere-node-utils' # name of the application
  serializers:
    request: reqSerializer # function that maps the request object with fields (uri, method, headers)
    response: resSerializer # function that maps the response object with fields (status, headers, body)
  src: false # includes a log of the call source location (file, line, function).
             # Determining the source call is slow, therefor it's recommended not to enable this on production.
  silent: false # don't instantiate the {Bunyan} logger, instead use `console`
  streams: [ # a list of streams that defines the type of output for log messages
    {level: 'info', stream: process.stdout}
    {level: 'debug', path: './sphere-node-utils-debug.log'}
  ]
```

> A `Logger` instance should be extended by the component that needs logging by providing the correct configuration

```coffeescript
{Logger} = require 'sphere-node-utils'

module.exports = class extends Logger

  # we can override here some of the configuration options
  @appName: 'my-application-name'
  @path: './my-application-name.log'
```

A `Bunyan` logger can also be created from another existing logger. This is useful to connect sub-components of the same application by sharing the same configuration.
This concept is called **[child logger](https://github.com/trentm/node-bunyan#logchild)**.

```coffeescript
{Logger} = require 'sphere-node-utils'
class MyCustomLogger extends Logger
  @appName: 'my-application-name'

myLogger = new MyCustomLogger logConfig

# assume we have a component which already implements logging
appWithLogger = new AppWithLogger
  logConfig:
    logger: myLogger

# now we can use `myLogger` to log and everything logged from the child logger of `AppWithLogger`
# will be logged with a `widget_type` field, meaning the log comes from the child logger
```

Once you configure your logger, you will get JSON stream of logs based on the level you defined. This is great for processing, but not for really human-friendly.
This is where the `bunyan` command-line tool comes in handy, by providing **pretty-printed** logs and **filtering**. More info [here](https://github.com/trentm/node-bunyan#cli-usage).

```bash
# examples

# this will output the content of the log file in a `short` format
bunyan sphere-node-connect-debug.log -o short
00:31:47.760Z  INFO sphere-node-connect: Retrieving access_token...
00:31:48.232Z  INFO sphere-node-connect: GET /products

# directly pipe the stdout stream
jasmine-node --verbose --captureExceptions test | ./node_modules/bunyan/bin/bunyan -o short
00:34:03.936Z DEBUG sphere-node-connect: OAuth constructor initialized. (host=auth.sphere.io, accessTokenUrl=/oauth/token, timeout=20000, rejectUnauthorized=true)
    config: {
      "client_id": "S6AD07quPeeTfRoOHXdTx2NZ",
      "client_secret": "7d3xSWTN5jQJNpnRnMLd4qICmfahGPka",
      "project_key": "my-project",
      "oauth_host": "auth.sphere.io",
      "api_host": "api.sphere.io"
    }
00:34:03.933Z DEBUG sphere-node-connect: Failed to retrieve access_token, retrying...1

```

##### Silent logs, use `console`
You can pass a `silent` flag to override the level functions of the `bunyan` logger (debug, info, ...) to print to stdout / stderr using console.

#### ExtendedLogger
An `ExtendedLogger` allows you to wrap additional fields to the logged JSON object, by either defining them on class instantiation or by chaining them before calling the log level method.

> Under the hood it uses the [Logger](#logger) `Bunyan` object

```coffeescript
logger = new ExtendedLogger
  additionalFields:
    project_key: 'foo'
    another_field: 'bar'
  logConfig: # see config above (Logger)
    streams: [
      { level: 'info', stream: process.stdout }
    ]

# then use the logger as usual

logger.info {id: 123}, 'Hello world'
# => {"name":"sphere-node-utils","hostname":"Nicolas-MacBook-Pro.local","pid":25856,"level":30,"id":123,"project_key":"foo","another_field":"bar","msg":"Hello world","time":"2014-04-17T10:54:05.237Z","v":0}

# or by chaining

logger.withField({token: 'qwerty'}).info {id: 123}, 'Hello world'
# => {"name":"sphere-node-utils","hostname":"Nicolas-MacBook-Pro.local","pid":25856,"level":30,"id":123,"project_key":"foo","another_field":"bar", "token": "qwerty","msg":"Hello world","time":"2014-04-17T10:54:05.237Z","v":0}
```

#### TaskQueue
A `TaskQueue` allows you to queue promises (or function that return promises) which will be executed in parallel sequentially, meaning that new tasks will not be triggered until the previous ones are resolved.

```coffeescript
{TaskQueue} = require 'sphere-node-utils'

callMe = ->
  new Promise (resolve, reject) ->
    setTimeout ->
      resolve true
    , 5000
task = new TaskQueue maxParallel: 50 # default 20
task.addTask callMe
.then (result) -> # result == true
.catch (error) ->
```

Available methods:
- `setMaxParallel` sets the `maxParallel` parameter (default is `20`). **If < 1 or > 100 it throws an error**
- `addTask` adds a task (promise) to the queue and returns a new promise

#### Sftp
Provides promised based wrapped functionalities for some `SFTP` methods

- `listFiles`
- `stats`
- `readFile` _not implemented yet_
- `saveFile` _not implemented yet_
- `getFile`
- `putFile`
- `safePutFile`
- `renameFile`
- `safeRenameFile`
- `removeFile`
- `openSftp`
- `close`
- `downloadAllFiles`

> The client using the `Sftp` helper should take care of how to send requests to manage remote files, by controlling e.g. concurrency via `TaskQueue` and/or functions of `Bluebird` promise [API](https://github.com/petkaantonov/bluebird/blob/master/API.md)


#### ProjectCredentialsConfig
Allows to read SPHERE.IO credentials from a file or via environment variables, based on the `project_key`.

##### From a file

By default the module will try to read the credentials from the following locations (descending priority):

* ./.sphere-project-credentials
* ./.sphere-project-credentials.json
* ~/.sphere-project-credentials
* ~/.sphere-project-credentials.json
* /etc/sphere-project-credentials
* /etc/sphere-project-credentials.json

The versions of these without the `.json` extension consist of a series of lines, each of which contains a project key, client ID and client secret, separated by colons:

```
<project-key1>:<client-id1>:<client-secret1>
<project-key2>:<client-id2>:<client-secret2>
```

The JSON versions are structured as follows:

```
{
  "<project-key1>": {
    "client_id":"<client-id1>",
    "client_secret":"<client-secret1>"
  },
  "<project-key2>": {
    "client_id":"<client-id2>",
    "client_secret":"<client-secret2>"
  }
}
```

Example usage:
```js
import { SphereClient } from 'sphere-node-sdk'
import { ProjectCredentialsConfig } from 'sphere-node-utils'

const PROJECT_KEY = 'your-project-key'

ProjectCredentialsConfig.create()
.then((credentials) =>{
  const sphereCredentials = credentials.enrichCredentials({
   project_key: PROJECT_KEY,
   // you can pass some fallback options as well here
   client_id: argv.clientId,
   client_secret: argv.clientSecret,
  })
  // got the credentials
  // do something with them e.g. initialize the SphereClient from the node-sdk
  const sphereClient = new SphereClient({ config: sphereCredentials })
})
```

##### From environment variables

This is a little bit more restricted, since you can only define one set of credentials with the environment variables. Nevertheless this is very useful for deployments, where you really only need one set of credentials per deployment.
You can define your credentials using these variables:

```sh
export SPHERE_PROJECT_KEY="your-project-key"
export SPHERE_CLIENT_ID="your-client-id"
export SPHERE_CLIENT_SECRET="your-client-secret"
```

#### ElasticIo
_(Coming soon)_

#### UserAgent
A synchronous module that builds _user\_agent_ according to the standard specified by commercetools

sphere-node-sdk module must be installed in the node_modules because it's required to build the user_agent

```js
const user_agent = userAgent('sphere-node-utils', '1.0.0')
```

Example of returned user_agent
```
1.16.2 Node.js/v6.5.0 (darwin; x64) sphere-node-utils/0.8.6
```

#### Repeater
A Repeater allows to execute a promise function and recover from it in case of errors, for a certain number of times before giving up.

> By default the initial task will be retried unless a new task is returned from the recover function (see example below).

The only method exposed is `execute`, which accepts 2 arguments:
- task: a `Function` that returns a Promise
- recover: a `Function` that returns a Promise, called when the task fails

Following options are supported when initializing a new `Repeater`:
- `attempts` (Int) how many times the task should be repeated, if failed, before giving up (**default 10**)
- `timeout` (Int) the delay between attempts before retrying, in `ms` (**default 100**)
- `timeoutType` (String) the type of the timeout (**default c**)
  - `c` _constant delay_ always the same timeout
  - `v` _variable delay_ timeout grows with the attempts count (also using a random component)

```coffeescript
client = new SphereClient {...}
repeater = new Repeater {attempts: 10}

updateTask = (payload) -> client.products.byId(productId).update(payload)
repeater.execute ->
  updateTask(payload)
, (e) ->
  if e.statusCode is 409
    # this means a concurrent modification, so we retry to update with
    # a new task by retrieving a new product version first
    newTask = -> # task must be a function
      client.productProjections.staged(true).byId(productId).fetch()
      .then (result) ->
        newPayload = _.extend payload, {version: result.body.version}
        updateTask(newPayload)
    # now we must resolve the recover function with the new task
    # If we just want to retry the initial task then simply resolve an empty promise
    # Promise.resolve()
    Promise.resolve newTask
  else
    # we should not retry in this case, so simply bubble up the error
    Promise.reject e
```

### Mixins
Currently following mixins are provided by `SphereUtils`:

- `Qutils`
  - `processList`

#### Qutils
> Deprecated in favour of `Bluebird` promises

A collections of Q utils (promise-based)

```coffeescript
{Qutils} = require 'sphere-node-utils'
```

##### `processList`
Process each element in the given list using the function `fn` (called on each iteration).
The function `fn` has to return a promise that should be resolved when all elements of the page are processed.

```coffeescript
list = [{key: '1'}, {key: '2'}, {key: '3'}]
processList list, (elems) -> # elems is an array
  doSomethingWith(elems) # it's a promise
  .then ->
    # something else
    anotherPromise()
```

> Note that the argument passed to the process function is always an array, containing a number of elements defined by `maxParallel` option

You can pass some options as second argument:
- `accumulate` whether the results should be accumulated or not (default `true`). If not, an empty array will be returned from the resolved promise.
- `maxParallel` how many elements from the list will be passed to the process `fn` function (default `1`)


## Examples
_(Coming soon)_

## Contributing
In lieu of a formal styleguide, take care to maintain the existing coding style. Add unit tests for any new or changed functionality. Lint and test your code using [Grunt](http://gruntjs.com/).
More info [here](CONTRIBUTING.md)

## Releasing
Releasing a new version is completely automated using the Grunt task `grunt release`.

```javascript
grunt release // patch release
grunt release:minor // minor release
grunt release:major // major release
```

## License
Copyright (c) 2014 SPHERE.IO
Licensed under the [MIT license](LICENSE-MIT).

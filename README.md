![SPHERE.IO icon](https://admin.sphere.io/assets/images/sphere_logo_rgb_long.png)

# NODE.JS Utils

[![Build Status](https://secure.travis-ci.org/sphereio/sphere-node-utils.png?branch=master)](http://travis-ci.org/sphereio/sphere-node-utils) [![Coverage Status](https://coveralls.io/repos/sphereio/sphere-node-utils/badge.png)](https://coveralls.io/r/sphereio/sphere-node-utils) [![Dependency Status](https://david-dm.org/sphereio/sphere-node-utils.png?theme=shields.io)](https://david-dm.org/sphereio/sphere-node-utils) [![devDependency Status](https://david-dm.org/sphereio/sphere-node-utils/dev-status.png?theme=shields.io)](https://david-dm.org/sphereio/sphere-node-utils#info=devDependencies)

This module shares helpers among all [SPHERE.IO](http://sphere.io/) Node.js components.

## Table of Contents
* [Getting Started](#getting-started)
* [Documentation](#documentation)
  * [Helpers](#helpers)
    * [Sftp](#sftp)
  * [Mixins](#mixins)
    * [Qbatch.all (batch processing)](#batch-processing)
    * [Qbatch.paged (batch processing of paged results)](#batch-processing)
* [Examples](#examples)
* [Releasing](#releasing)
* [License](#license)


## Getting Started
> This module is `**private**` and will not be published to NPM registry at the moment

To install the module simply require it as dependency in the `package.json` using a Git URL and specifying the correct tag as a hash parameter.

```json
{
  ...
  "dependencies": {
    "sphere-node-utils": "sphereio/sphere-node-utils.git#v0.1.0"
  },
  ...
}
```

Then require it as a normal dependency

```coffeescript
SphereUtils = require 'sphere-node-utils'

{Sftp} = require 'sphere-node-utils'
```

## Documentation

### Helpers
Currently following helpers are provided by `SphereUtils`:

- `Sftp`

#### Sftp
_(Coming soon)_

### Mixins
Currently following mixins are provided by `SphereUtils`:

- `Qbatch`
  - `all`
  - `paged`

#### Qbatch.all (batch processing)
Batch processing allows a list of promises to be executed in chunks, by defining a limit to how many requests can be sent in parallel.
The `Qbatch.all` function is actually a promise itself which recursively resolves all given promises in batches.

```coffeescript
# let's assume we have a bunch of promises (e.g.: 200)
allPromises = [p1, p2, p3, ...]

Qbatch.all(allPromises)
.then (result) ->
.fail (error) ->
```

Default max number of parallel request is `**50**`, you can configure this in the second argument.

```coffeescript
# with custom limit (max number of parallel requests)
Qbatch(allPromises, 100)
.then (result) ->
.fail (error) ->
```

You can also subscribe to **progress notifications** of the promise

```coffeescript
Qbatch(allPromises)
.then (result) ->
.progress (progress) ->
  # progress is an object containing the current progress percentage
  # and the value of the current results (array)
  # {percentage: 20, value: [r1, r2, r3, ...]}
.fail (error) ->
```

#### Qbatch.paged (batch processing of paged results)
Batch processing of paged results allows to safely query all results (=> `limit=0`) in chunks.
The `Qbatch.paged` function is actually a promise itself which recursively accumulates the paged results, returning all of them together.

```coffeescript
rest = new Rest options

Qbatch.paged(rest, '/products')
.then (result) ->
.fail (error) ->
```

> Note that ba using this function, the `limit` is considered to be 0, meaning all results are queried. So given `limit` and `offset` parameters will be ignored.

```coffeescript
# with query params
rest = new Rest options

Qbatch.paged(rest, '/products?where=name%3D%22Foo%22&staged=true')
.then (result) ->
.fail (error) ->
```

You can also subscribe to **progress notifications** of the promise

```coffeescript
Qbatch(rest, '/products')
.then (result) ->
.progress (progress) ->
  # progress is an object containing the current progress percentage
  # and the value of the current results (array)
  # {percentage: 20, value: [r1, r2, r3, ...]}
.fail (error) ->
```

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

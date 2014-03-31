_ = require 'underscore'
_u = require '../../lib/mixins/underscore'
_.mixin require('underscore.string').exports()

describe 'Mixins', ->

  describe 'underscore.string', ->

    it 'should mix in with underscore without conflicts', ->
      u = _.union [{key: 'foo'}, {key: 'bar'}, {key: 'qux'}], [], []
      expect(u).toEqual [{key: 'foo'}, {key: 'bar'}, {key: 'qux'}]

  describe '_u', ->

    it 'should extend underscore', ->
      _.mixin _u
      expect(_.deepClone).toBeDefined()
      expect(_.percentage).toBeDefined()
      expect(_.stringifyQuery).toBeDefined()
      expect(_.parseQuery).toBeDefined()

  describe '_u :: deepClone', ->

    it 'should clone an object deeply', ->
      obj =
        a: [
          {one: "One"}
          {two: "Two"}
          {three: "Three"}
        ]
        b:
          c:
            d:
              e:
                f:
                  g: [
                    {one: "One"}
                    {two: "Two"}
                    {three: "Three"}
                  ]
      expectedObj =
        a: [
          {one: "One"}
          {two: "Two"}
          {three: "Three"}
        ]
        b:
          c:
            d:
              e:
                f:
                  g: [
                    {one: "One"}
                    {two: "Two"}
                    {three: "Three"}
                  ]
      expect(_u.deepClone(obj)).toEqual expectedObj

  describe '_u :: percentage', ->

    it 'should calculate value', ->
      expect(_u.percentage 10, 100).toBe 10

    it 'should calculate rounded value', ->
      expect(_u.percentage 33, 1010).toBe 3

  describe '_u :: stringifyQuery', ->

    it 'should parse string from object', ->
      query = _u.stringifyQuery
        where: encodeURIComponent('name = "Foo"')
        staged: true
        limit: 100
        offset: 2

      expect(query).toBe 'where=name%20%3D%20%22Foo%22&staged=true&limit=100&offset=2'

    it 'should return empty string if object is not defined', ->
      expect(_u.stringifyQuery()).toBe ''
      expect(_u.stringifyQuery({})).toBe ''

  describe '_u :: parseQuery', ->

    it 'should parse object from string', ->
      params = _u.parseQuery 'where=name%20%3D%20%22Foo%22&staged=true&limit=100&offset=2'

      expect(params).toEqual
        where: encodeURIComponent('name = "Foo"')
        staged: 'true'
        limit: '100'
        offset: '2'

    it 'should return empty object if string is not defined', ->
      expect(_u.parseQuery()).toEqual {}
      expect(_u.parseQuery('')).toEqual {}

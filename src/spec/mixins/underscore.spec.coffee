_ = require 'underscore'
_u = require '../../lib/mixins/underscore'

describe 'Mixins', ->

  describe '_u', ->

    it 'should extend underscore', ->
      _.mixin _u
      expect(_.deepClone).toBeDefined()
      expect(_.toQueryString).toBeDefined()
      expect(_.fromQueryString).toBeDefined()

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

  describe '_u :: toQueryString', ->

    it 'should parse string from object', ->
      query = _u.toQueryString
        where: encodeURIComponent('name = "Foo"')
        staged: true
        limit: 100
        offset: 2

      expect(query).toBe 'where=name%20%3D%20%22Foo%22&staged=true&limit=100&offset=2'

    it 'should return empty string if object is not defined', ->
      expect(_u.toQueryString()).toBe ''
      expect(_u.toQueryString({})).toBe ''

  describe '_u :: fromQueryString', ->

    it 'should parse object from string', ->
      params = _u.fromQueryString 'where=name%20%3D%20%22Foo%22&staged=true&limit=100&offset=2'

      expect(params).toEqual
        where: encodeURIComponent('name = "Foo"')
        staged: 'true'
        limit: '100'
        offset: '2'

    it 'should return empty object if string is not defined', ->
      expect(_u.fromQueryString()).toEqual {}
      expect(_u.fromQueryString('')).toEqual {}

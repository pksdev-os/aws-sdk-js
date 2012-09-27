AWS = require('../../lib/core')
require('../../lib/query_service')
require('../../lib/sigv2')

describe 'AWS.SignatureV2Signer', ->

  credentials = null
  date = null
  request = null
  signer = null

  buildRequest = ->
    request = new AWS.HttpRequest()
    request.endpoint = new AWS.Endpoint({ region: 'us-west-1' })
    request.endpoint.host = 'locahost'
    request.params = new AWS.QueryParamList()
    request

  buildSigner = (request) ->
    new AWS.SignatureV2Signer(request)

  signRequest = (request) ->
    signer = new AWS.SignatureV2Signer(request)
    signer.addAuthorization(credentials, date)

  beforeEach ->
    credentials = { accessKeyId:'akid', secretAccessKey:'secret' }
    date = new Date(1935346573456)
    signRequest(buildRequest())

  describe 'constructor', ->

    it 'builds a signer for a request object', ->
      expect(signer.request).toBe(request)

  describe 'addAuthorization', ->

    it 'adds a url encoded iso8601 timestamp param', ->
      expect(request.params.toString()).toMatch(/Timestamp=2031-04-30T20%3A16%3A13.456Z/)

    it 'adds a SignatureVersion param', ->
      expect(request.params.toString()).toMatch(/SignatureVersion=2/)

    it 'adds a SignatureMethod param', ->
      expect(request.params.toString()).toMatch(/SignatureMethod=HmacSHA256/)

    it 'adds an AWSAccessKeyId param', ->
      expect(request.params.toString()).toMatch(/AWSAccessKeyId=akid/)

    it 'omits SecurityToken when sessionToken has been omitted', ->
      expect(request.params.toString()).not.toMatch(/SecurityToken/)

    it 'adds the SecurityToken when sessionToken is provided', ->
      credentials.sessionToken = 'session'
      signRequest(buildRequest())
      expect(request.params.toString()).toMatch(/SecurityToken=session/)

    it 'populates the body', ->
      expect(request.body).toEqual('AWSAccessKeyId=akid&Signature=a78P5VVSxdpSke0jfVIc%20ZLMyREIPcaNwbtBiBdN070%3D&SignatureMethod=HmacSHA256&SignatureVersion=2&Timestamp=2031-04-30T20%3A16%3A13.456Z')

    it 'populates content-length header', ->
      expect(request.headers['Content-Length']).toEqual(163)

    it 'signs additional body params', ->
      request = buildRequest()
      request.params.add('Param.1', 'abc')
      request.params.add('Param.2', 'xyz')
      signRequest(request)
      expect(request.body).toEqual('AWSAccessKeyId=akid&Param.1=abc&Param.2=xyz&Signature=9IXfN6PmgrIdEuP8MSltyExyhTjVZEuXAUq6NKT8qDE%3D&SignatureMethod=HmacSHA256&SignatureVersion=2&Timestamp=2031-04-30T20%3A16%3A13.456Z')


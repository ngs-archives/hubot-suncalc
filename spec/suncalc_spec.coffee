path = require 'path'
fs = require 'fs'
Robot = require("hubot/src/robot")
TextMessage = require("hubot/src/message").TextMessage
nock = require 'nock'
chai = require 'chai'
sinon = require 'sinon'
chai.use require 'sinon-chai'
{ expect } = chai

describe 'hubot-suncalc', ->
  robot = null
  user = null
  user2 = null
  adapter = null
  nockScope = null
  clock = null

  ginzaCandidates = """
                    Found 12 locations for "ginza".
                    Answer leading index number:
                    1. Ginza, Chūō, Tokyo, Japan
                    2. Ginza, Kumagaya, Saitama Prefecture, Japan
                    3. Ginza, Honjo, Saitama Prefecture, Japan
                    4. Ginza, Shimizu Ward, Shizuoka, Shizuoka Prefecture, Japan
                    5. Ginza, Shunan, Yamaguchi Prefecture, Japan
                    6. Ginza, Okaya, Nagano Prefecture, Japan
                    7. Ginza, Tobata Ward, Kitakyushu, Fukuoka Prefecture, Japan
                    8. Ginza, Iida, Nagano Prefecture, Japan
                    9. Ginza, Kariya, Aichi Prefecture, Japan
                    10. Ginza, Tokushima, Tokushima Prefecture, Japan
                    11. Ginza, Kanuma, Tochigi Prefecture, Japan
                    12. Ginza, Angola
                    """

  mockResult = (query, filename)->
    nock.disableNetConnect()
    nockScope = nock('http://maps.googleapis.com')
      .get("/maps/api/geocode/json?language=en&address=#{query}")
      .replyWithFile 200, "#{__dirname}/fixtures/#{filename}.json"

  adapterEvent = (event, done, example)->
    adapter.once event, ->
      try
        example.apply this, arguments
      catch e
        done e

  beforeEach (done)->
    robot = new Robot null, 'mock-adapter', yes, 'TestHubot'
    robot.adapter.on 'connected', ->
      robot.loadFile path.resolve('.', 'src', 'scripts'), 'suncalc.coffee'
      hubotScripts = path.resolve 'node_modules', 'hubot', 'src', 'scripts'
      robot.loadFile hubotScripts, 'help.coffee'
      user = robot.brain.userForId '1', {
        name: 'ngs'
        room: '#mocha'
      }
      user2 = robot.brain.userForId '2', {
        name: 'pyc'
        room: '#mocha'
      }
      adapter = robot.adapter
      waitForHelp = ->
        if robot.helpCommands().length > 0
          do done
        else
          setTimeout waitForHelp, 100
      do waitForHelp
    do robot.run

  afterEach ->
    clock?.restore()
    clock = null
    nock.cleanAll()
    robot.server.close()
    robot.shutdown()
    robot.cloudfront?.watcher.stop()
    process.removeAllListeners 'uncaughtException'

  describe 'help', ->
    it 'should have 5', (done)->
      expect(robot.helpCommands()).to.have.length 5
      do done

    it 'should parse help', (done)->
      adapterEvent 'send', done, (envelope, strings)->
        expect(strings).to.deep.equal ["""
        TestHubot help - Displays all of the help commands that TestHubot knows about.
        TestHubot help <query> - Displays all help commands that match <query>.
        TestHubot moonphase - Replies moonphase of the date.
        TestHubot sunrise <location> - Replies sunrise of the date.
        TestHubot sunset <location> - Replies sunset of the date.
        """]
        do done
      adapter.receive new TextMessage user, 'TestHubot help'

  describe 'suncalc', ->
    beforeEach ->
      clock = sinon.useFakeTimers new Date('Sun, 10 Aug 2014 00:00:00 GMT').getTime(), 'Date'

    describe 'sunrise', ->
      it 'replies time if found 1 location', (done)->
        mockResult 'taipei', 'single'
        adapterEvent 'send', done, (envelope, strings)->
          expect(envelope).not.to.be.null
          expect(strings).to.deep.equal ['Sunrise in Taipei City, Taiwan is 06:26 AM']
          do done
        adapter.receive new TextMessage user, 'testhubot  sunrise  taipei  '
      it 'ask selection if found multiple locations', (done)->
        mockResult 'ginza', 'multiple'
        adapterEvent 'reply', done, (envelope, strings)->
          expect(robot.listeners).to.have.length 5
          expect(envelope).not.to.be.null
          expect(strings).to.deep.equal [ginzaCandidates]
          adapterEvent 'send', done, (envelope, strings)->
            expect(robot.listeners).to.have.length 4
            expect(strings).to.deep.equal ['Sunrise in Ginza, Tobata Ward, Kitakyushu, Fukuoka Prefecture, Japan is 05:35 AM']
            do done
          adapter.receive new TextMessage user2, '  5 '
          expect(robot.listeners).to.have.length 5
          adapter.receive new TextMessage user, '  7  '
        expect(robot.listeners).to.have.length 4
        adapter.receive new TextMessage user, 'testhubot  sunrise  ginza  '

    describe 'sunset', ->
      it 'replies time if found 1 location', (done)->
        mockResult 'taipei', 'single'
        adapterEvent 'send', done, (envelope, strings)->
          expect(envelope).not.to.be.null
          expect(strings).to.deep.equal ['Sunset in Taipei City, Taiwan is 07:34 PM']
          do done
        adapter.receive new TextMessage user, 'testhubot  sunset  taipei  '
      it 'ask selection if found multiple locations', (done)->
        mockResult 'ginza', 'multiple'
        adapterEvent 'reply', done, (envelope, strings)->
          expect(robot.listeners).to.have.length 5
          expect(envelope).not.to.be.null
          expect(strings).to.deep.equal [ginzaCandidates]
          adapterEvent 'send', done, (envelope, strings)->
            expect(robot.listeners).to.have.length 4
            expect(strings).to.deep.equal ['Sunset in Ginza, Tobata Ward, Kitakyushu, Fukuoka Prefecture, Japan is 07:11 PM']
            do done
          adapter.receive new TextMessage user2, '  5 '
          expect(robot.listeners).to.have.length 5
          adapter.receive new TextMessage user, '  7  '
        expect(robot.listeners).to.have.length 4
        adapter.receive new TextMessage user, 'testhubot  sunset  ginza  '
    describe 'moonphase', ->
      it 'replies moonphase', (done)->
        adapterEvent 'send', done, (envelope, strings)->
          expect(envelope).not.to.be.null
          expect(strings).to.deep.equal ['🌕  46.83%']
          do done
        adapter.receive new TextMessage user, 'testhubot  moonphase  '

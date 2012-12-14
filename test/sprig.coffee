if _dom?
  require("./_dom")
  $ = require("jquery")
  expect = require("expect.js")
  sinon = require("sinon")
  Component = require("../")
else
  {$, expect, sinon} = window
  Component = window.Sprig

after = (ms, f)-> setTimeout(f, ms);

describe "Sprig", ->
  $component = null
  Sprig = null
  beforeEach ->
    Sprig = new Component(document.body)
    $component = $("<div data-sprig-component='some.component'></div>")
  afterEach ->
    $component.remove()

  describe "Scanning for and initialization of components", ->
    it "Calls the initializer for an uninitialized element is called", ->
      spy = sinon.spy()
      Sprig.define('some.component').initEach(spy)
      $(document.body).append($component)
      Sprig.scan()
      expect(spy.called).to.be(true)

    it "Doesn't load the component for an element more than once", ->
      spy = sinon.spy()
      Sprig.define('some.component').initEach(spy)
      $(document.body).append($component)
      Sprig.scan()
      Sprig.scan()
      expect(spy.calledOnce).to.be(true)

    it "Doesn't load the component for a nested element more than once", ->
      spy = sinon.spy()
      Sprig.define('some.component').initEach(spy)
      $component.append($("<div data-sprig-component='some.component'></div>"))
      $(document.body).append($component)
      Sprig.scan()
      expect(spy.calledTwice).to.be(true)

  describe "Component ready states", ->
    it "Get ready state deferred if component element is detected before its defined", ->
      $(document.body).append($component)
      Sprig.scan()
      expect($component[0].dataset.sprigReadyState).to.be("deferred")

    it "Is gets initialized after its defined if its previously deferred", (done)->
      $(document.body).append($component)
      Sprig.scan()
      spy = sinon.spy()
      Sprig.define('some.component').initEach(spy)
      expect(spy.calledOnce).to.be.ok
      # Wait a few mseconds because deferred components are not loaded synchronously
      after 10, ->
        expect($component[0].dataset.sprigReadyState).to.be("loaded")
        done()

  describe "Async components", ->
    it "Will not rescan for new child-components before initializer is called for an async component", (done)->
      spy = sinon.spy()
      Sprig.define('some.other.component').initEach(spy)

      Sprig.define('some.component').async().initEach (component)->
        after 30, ->
          component.$el.html("<span data-sprig-component='some.other.component'></span>")
          component.finalize();

      $(document.body).append($component)
      Sprig.scan()
      expect(spy.called).to.be(false)
      after 60, ->
        expect(spy.called).to.be(true)
        done()

  describe "Legacy API", ->
    Sprig = null
    beforeEach ->
      Sprig = window.Sprig

    it "Keeps an old Sprig.add method intact", ->
      spy = sinon.spy()
      Sprig.add 'some.component', spy
      $(document.body).append($component)
      Sprig.load()
      expect(spy.firstCall.args.length).to.equal(2)
      expect(spy.calledOnce).to.be(true)
      expect(spy.firstCall.args[0][0]).to.equal($component[0])
      expect(spy.firstCall.args[1]).to.equal($component[0].dataset)

    it "Keeps an old Sprig.add method intact, also for async components", (done)->
      spyAsyncInit = sinon.spy()
      spyNested = sinon.spy()
      Sprig.add 'some.component', ($el, opts, finalize)->
        spyAsyncInit($el, opts, finalize);

        after 30, ->
          $el.html("<span data-sprig-component='some.other.component'></span>")
          finalize()

      Sprig.define('some.other.component').initEach(spyNested)

      $(document.body).append($component)
      Sprig.load()

      expect(spyAsyncInit.called).to.be(true)
      expect(spyAsyncInit.firstCall.args.length).to.equal(3)
      expect(spyNested.calledOnce).to.be(false)
      after 60, ->
        expect(spyNested.calledOnce).to.be(true)
        done()

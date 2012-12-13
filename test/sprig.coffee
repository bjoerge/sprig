if _dom?
  require("./_dom")
  $ = require("jquery")
  expect = require("expect.js")
  sinon = require("sinon")
  Sprig = require("../")
else
  {$, expect, sinon, Sprig} = window

after = (ms, f)-> setTimeout(f, ms);

describe "Sprig", ->
  $component = null
  beforeEach ->
    $component = $("<div data-sprig-component='some.component'></div>")
  afterEach ->
    $component.remove()

  describe "Scanning and loading components", ->

    it "Calls the initializer for an uninitialized element is called", ->
      spy = sinon.spy()
      Sprig.define('some.component').one(spy)
      $(document.body).append($component)
      Sprig.scan()
      expect(spy.called).to.be(true)

    it "Doesn't load the component for an element more than once", ->
      spy = sinon.spy()
      Sprig.define('some.component').one(spy)
      $(document.body).append($component)
      Sprig.scan()
      Sprig.scan()
      expect(spy.calledOnce).to.be(true)

    it "Doesn't load the component for a nested element more than once", ->
      spy = sinon.spy()
      Sprig.define('some.component').one(spy)
      $component.append($("<div data-sprig-component='some.component'></div>"))
      $(document.body).append($component)
      Sprig.scan()
      expect(spy.calledTwice).to.be(true)

  describe "Async components", ->
    it "Will not rescan for new child-components before initializer is called for an async component", ->
      spy = sinon.spy()
      Sprig.define('some.other.component').one(spy)

      Sprig.define('some.component').async().one (component)->
        component.$el.html("<span data-sprig-component='some.other.component'></span>")
        after 30, -> component.finalize();

      $(document.body).append($component)
      Sprig.scan()
      expect(spy.called).to.be(false)
      after 60, -> expect(spy.called).to.be(true)

  describe "Legacy API", ->
    it "Keeps an old Sprig.add method intact", ->
      spy = sinon.spy()
      Sprig.add 'some.component', spy
      $(document.body).append($component)
      Sprig.load()
      expect(spy.firstCall.args.length).to.equal(2)
      expect(spy.calledOnce).to.be(true)
      expect(spy.firstCall.args[0][0]).to.equal($component[0])
      expect(spy.firstCall.args[1]).to.equal($component[0].dataset)

    it "Keeps an old Sprig.add method intact, also for async components", ->
      spyAsyncInit = sinon.spy()
      spyNested = sinon.spy()
      Sprig.add 'some.component', ($el, opts, done)->
        spyAsyncInit($el, opts, done);
        $el.html("<span data-sprig-component='some.other.component'></span>")
        after 30, done

      Sprig.define('some.other.component').one(spyNested)

      $(document.body).append($component)
      Sprig.load()

      expect(spyAsyncInit.called).to.be(true)
      expect(spyAsyncInit.firstCall.args.length).to.equal(3)
      expect(spyNested.calledOnce).to.be(false)
      after 60, -> expect(spyNested.calledOnce).to.be(true)

if _dom?
  require("./_dom")
  $ = require("jquery")
  expect = require("expect.js")
  sinon = require("sinon")
  Component = require("../").Component
else
  {$, expect, sinon} = window
  Component = window.Sprig.Component

after = (ms, f)-> setTimeout(f, ms);

describe "Sprig", ->
  $component = null
  Sprig = null
  beforeEach ->
    Sprig = new Component(document.body)
    $component = $('<div data-sprig-component="some.component" data-attr1="foo" data-attr2="bar"></div>')
  afterEach ->
    $component.remove()

  describe "Attributes", ->
    it "Maps data-* attributes to the component's params property", (done)->
      Sprig.define('some.component').init (component)->
        expect(component.params).to.eql(sprigComponent: "some.component", sprigReadyState: "loading", attr1: "foo", attr2: "bar")
        done()
      $(document.body).append($component)
      Sprig.scan()

  describe "Scanning for and initialization of components", ->
    it "Calls the initializer for an uninitialized element is called", ->
      spy = sinon.spy()
      Sprig.define('some.component').init(spy)
      $(document.body).append($component)
      Sprig.scan()
      expect(spy.called).to.be(true)

    it "Doesn't load the component for an element more than once", ->
      spy = sinon.spy()
      Sprig.define('some.component').init(spy)
      $(document.body).append($component)
      Sprig.scan()
      Sprig.scan()
      expect(spy.calledOnce).to.be(true)

    it "Doesn't load the component for a nested element more than once", ->
      spy = sinon.spy()
      Sprig.define('some.component').init(spy)
      $component.append($("<div data-sprig-component='some.component'></div>"))
      $(document.body).append($component)
      Sprig.scan()
      expect(spy.calledTwice).to.be(true)

  describe "Nested components", ->
    it "Allows for nested components", (done)->
      $child = $("""<div data-sprig-component="some.component.child"></div>""")
      $component.append($child)
      $(document.body).append($component)

      fail = after 100, -> expect().fail -> "Child component not initialized"

      Sprig.define("some.component").init (component)->
        expect($child.attr("data-sprig-ready-state")).to.be("deferred")
        component.define("child").init ->
          clearTimeout fail
          done()

      Sprig.scan()

    it "allows for nested components at deeper levels", (done)->
      $child = $("""<div data-sprig-component="some.component.child"></div>""")
      $grandchild = $("""<div data-sprig-component="some.component.child.child"></div>""")
      $child.append($grandchild)
      $component.append($child)
      $(document.body).append($component)

      fail = after 100, -> expect().fail -> "Child component not initialized"
      Sprig.define("some.component").init (component)->
        expect($child.attr("data-sprig-ready-state")).to.be("deferred")
        component.define("child").init (child)->
          child.define("child").init ->
            clearTimeout fail
            done()

      Sprig.scan()

  describe "Component ready states", ->
    it "Get ready state deferred if component element is detected before its defined", ->
      $(document.body).append($component)
      Sprig.scan()
      expect($component.attr("data-sprig-ready-state")).to.be("deferred")

    it "Is gets initialized after its defined if its previously deferred", (done)->
      $(document.body).append($component)
      Sprig.scan()
      spy = sinon.spy()
      Sprig.define('some.component').init(spy)
      expect(spy.calledOnce).to.be.ok
      # Wait a few mseconds because deferred components are not loaded synchronously
      after 10, ->
        expect($component.attr("data-sprig-ready-state")).to.be("loaded")
        done()

  describe "Async components", ->
    it "Will not rescan for new child-components before initializer is called for an async component", (done)->
      spy = sinon.spy()
      Sprig.define('some.other.component').init(spy)

      Sprig.define('some.component').async().init (component)->
        after 30, ->
          component.$el.html("<span data-sprig-component='some.other.component'></span>")
          component.finalize();

      $(document.body).append($component)
      Sprig.scan()
      expect(spy.called).to.be(false)
      after 60, ->
        expect(spy.called).to.be(true)
        done()

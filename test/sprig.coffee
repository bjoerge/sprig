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
  $el = null
  Sprig = null
  beforeEach ->
    Sprig = new Component(document.body)
    $el = $('<div data-sprig-component="some.component" data-attr1="foo" data-attr2="bar"></div>')
  afterEach ->
    $el.remove()

  describe "Attributes", ->
    it "Maps data-* attributes to the component's params property", (done)->
      Sprig.define('some.component').init (component)->
        expect(component.params).to.eql(sprigComponent: "some.component", sprigReadyState: "loading", attr1: "foo", attr2: "bar")
        done()
      $(document.body).append($el)
      Sprig.scan()

  describe "Scanning for and initialization of components", ->
    it "Calls the initializer for an uninitialized element is called", (done)->
      fail = after 100, -> expect().fail -> "Component never initialized"

      Sprig.define('some.component').init ->
        clearTimeout(fail)
        done()

      $(document.body).append($el)
      Sprig.scan()

    it "Doesn't load the component for an element more than once", (done)->
      spy = sinon.spy()
      Sprig.define('some.component').init spy
      $(document.body).append($el)
      Sprig.scan()
      after 10, ->
        Sprig.scan()
        after 10, ->
          expect(spy.calledOnce).to.be(true)
          done()

    it "Doesn't load the component for a nested element more than once", (done)->
      spy = sinon.spy()
      Sprig.define('some.component').init(spy)
      $el.append($("<div data-sprig-component='some.component'></div>"))
      $(document.body).append($el)
      Sprig.scan()
      after 100, ->
        expect(spy.calledTwice).to.be(true)
        done()

  describe "Nested components", ->
    it "Allows for nested components", (done)->
      $child = $("""<div data-sprig-component="some.component.child"></div>""")
      $el.append($child)
      $(document.body).append($el)

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
      $el.append($child)
      $(document.body).append($el)

      fail = after 100, -> expect().fail -> "Child component not initialized"
      Sprig.define("some.component").init (component)->
        expect($child.attr("data-sprig-ready-state")).to.be("deferred")
        component.define("child").init (child)->
          child.define("child").init ->
            clearTimeout fail
            done()

      Sprig.scan()

  describe "Component ready states", ->
    it "Get ready state deferred if component element is detected before its defined", (done)->
      $(document.body).append($el)
      Sprig.scan()
      after 30, ->
        expect($el.attr("data-sprig-ready-state")).to.be("deferred")
        done()

    it "Is gets initialized after its defined if its previously deferred", (done)->
      $(document.body).append($el)
      Sprig.scan()
      spy = sinon.spy()
      Sprig.define('some.component').init(spy)
      expect(spy.calledOnce).to.be.ok
      # Wait a few mseconds because deferred components are not loaded synchronously
      after 30, ->
        expect($el.attr("data-sprig-ready-state")).to.be("loaded")
        done()

  describe "Async components", ->
    it "Will not rescan for new child-components before initializer is called for an async component", (done)->
      spy = sinon.spy()
      Sprig.define('some.other.component').init(spy)

      Sprig.define('some.component').init (component)->
        after 30, ->
          expect(spy.called).to.be(false)
          component.el.innerHTML = "<span data-sprig-component='some.other.component'></span>"
          component.scan()
          after 30, ->
            expect(spy.called).to.be(true)
            done()

      $(document.body).append($el)
      Sprig.scan()

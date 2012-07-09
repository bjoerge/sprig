require("./_dom") unless window?
require("jquery")

expect = require("expect.js")
sinon = require("sinon")
$ = require("jquery")

Sprig = require("../lib/sprig")


describe "Sprig", ->

  it "Calls the setupFunction when Sprig.load() is called", ->
    spy = sinon.spy()
    Sprig.add 'mock', spy
    $(document.body).append("<div data-sprig-component='mock'></div>")
    Sprig.load(document.body)
    expect(spy.called).to.be(true)
  
  it "Needs more tests", ->
    

mocha = window.mocha

mocha.setup("bdd")

require("./reloader").connect(host: document.domain)

window.Sprig = require("../lib/sprig")
require("../test/sprig")
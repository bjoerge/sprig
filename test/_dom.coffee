# Setup for a global DOM-like environment for Node.js
jsdom = require("jsdom")

document = jsdom.jsdom('<html><body></body></html>')
window = document.createWindow();
window.document = document;
window.location = require('location');

global.document = document
global.window = window
global.navigator = require("navigator")

global._dom = true
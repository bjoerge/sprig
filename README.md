![Sprig](http://bjoergenaess.no/sprig.jpg?new-cache-key-pls)

# DISCLAIMER: Work in progress

# Getting started

Download [uncompressed](http://raw.github.com/bjoerge/sprig/master/sprig.js) (~ 6,5KB) 
or [minified](raw.github.com/bjoerge/sprig/master/sprig.min.js) (~ 4KB)

Currently Sprig depends on [jQuery](http://jquery.com).

# Usage examples

## Hello world

Register the hello-world component by calling the `Sprig.add()` function. It takes two parameters, `componentId` and `setupFunction`

The `setupFunction` is called whenever an element with the attribute `data-sprig-component='hello-word'` is inserted to the DOM.

```js
Sprig.add('hello-world', function(el, opts) {
  el.innerHTML = "Hello World!";
});
```

Inserting a `hello-world` component to the body:

```js
document.body.innerHTML = '<div data-sprig-component="hello-world"></div>';
Sprig.load(document.body); // <-- can be skipped in newer versions of Chrome and Firefox
```

Will result in:

```
Hello World
```

## Nesting

Components inserting other components just works:

```js
Sprig.add('parent', function(el, opts) {
  el.innerHTML = 'I am the parent. This is my child: <div data-sprig-component="child"></div>';
});

Sprig.add('child', function(el, opts) {
  el.innerHTML = 'I am the child.';
});
```

Inserting a `parent` component to the body:

```js
document.body.innerHTML = '<div data-sprig-component="parent"></div>';
Sprig.load(document.body);
```

... will result in:

```
I am the parent. This is my child:
I am the child.
```

## Passing data

For convenience, all the HTML5 data-* attributes defined on the element are passed as second parameter to the
`setupFunction`

For newer browsers this is a reference to the elements' `dataset` property

```js
Sprig.add('hello-planet', function(el, opts) {
  el.innerHTML = 'Hello '+(opts.planet || 'mysterious planet');
});
```

Inserting this `hello-planet` component to the body:

```js
document.body.innerHTML = '<div data-sprig-component="hello-planet"></div>';

var moon = document.createElement("div");
moon.setAttribute("data-sprig-component", "hello-planet");
moon.setAttribute("data-planet", "moon");
document.body.appendChild(moon);
Sprig.load(document.body);
```

... will result in:

```
Hello mysterious planet
Hello moon
```

## Asynchronous components

Quite often you'll need to request data from the server, wait for the server to return it before displaying it. 

If the `setupFunction` takes three parameters, it is assumed to be async, and will pass a `done` function that is to 
be called when the asynchronous action is complete.

```js
Sprig.add('async-component', function(el, opts, done) {
  $.get("/some/data.json").then(function(data) {
    el.innerHTML = "The server gave me this value: <b>"+data.value+"</b>";
    done();
  });
  el.innerHTML = "Requesting data from server...";
});
```

# How does it work?

In bleeding edge browsers supporting [Mutation Observers](http://dvcs.w3.org/hg/domcore/raw-file/tip/Overview.html#mutation-observers)
(currently only Chrome and Firefox), Sprig works by observing changes to the DOM tree. This, however, only works
for nodes inserted dynamically from JavaScript. If you serve a HTML file already layed out with components, then you will 
have to set them up initially, e.g. on domReady, like this:

```js
$(function() {
  Sprig.load(document.body);
});
```

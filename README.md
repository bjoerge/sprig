![Sprig](http://bjoergenaess.no/sprig.jpg?new-cache-key-pls)

[![Build Status](https://secure.travis-ci.org/bjoerge/sprig.png?branch=master)](https://travis-ci.org/bjoerge/sprig)

# Getting started

Download [uncompressed](http://raw.github.com/bjoerge/sprig/master/sprig.js) (~ 6,5KB) 
or [minified](http://raw.github.com/bjoerge/sprig/master/sprig.min.js) (~ 4KB)

Sprig has no dependencies but *can* be used with jquery by setting Sprig.$ to an instance of jquery like this:

```
Sprig.$ = window.jQuery
```

Now component instances will have an `$el` reference which is `component.el` as wrapped by `$()`.

# Usage examples

## Hello world

Register the hello-world component by calling the `Sprig.define()` method. It takes one parameter a `componentId` and
returns a component definition. The component definition can then be configured with an init function, which will be called
every time a matching component is detected in the DOM.

```js
Sprig.define('hello-world').init(function(component) {
  component.el.innerHTML = "Hello World!";
});
```

Inserting a `hello-world` component to the body:

```js
document.body.innerHTML = '<div data-sprig-component="hello-world"></div>';
Sprig.scan(document.body); // Will look for and initialize any uninitialized components found in the document body.
```

Will result in:

```
Hello World
```

## Nesting

Components inserting other components just works:

```js
Sprig.define('parent').init(function(component) {
  component.el.innerHTML = 'I am the parent. This is my child: <div data-sprig-component="child"></div>';
});

Sprig.define('child').init(function(component) {
  component.el.innerHTML = 'I am the child.';
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

For convenience, all the HTML5 data-* attributes defined on the element are attached to the component's `param`
property.

Note: For browsers that supports HTML5 data-* attributes, this is a reference to the elements' `dataset` property

```js
Sprig.define('hello-planet').init(function(component) {
  el.innerHTML = 'Hello '+(component.params.planet || 'mysterious planet');
});
```

Inserting this `hello-planet` component to the body:

```js
// planet component with no params
document.body.innerHTML = '<div data-sprig-component="hello-planet"></div>';

// planet component with planet set to moon
var moon = document.createElement("div");
moon.setAttribute("data-sprig-component", "hello-planet");
moon.setAttribute("data-planet", "moon");
document.body.appendChild(moon);
Sprig.scan(document.body);
```

... will result in:

```
Hello mysterious planet
Hello moon
```

## Asynchronous components

A common scenario is the need to request data from the server and wait for the server to return it before displaying it.
If you are inserting child-components into the component element asynchronously, you will have to call `component.scan()`
in order to have Sprig looking for newly arrived and uninitalized components.

```js
Sprig.define('some-async-component').init(function(component) {
  setTimeout(function(planet) {
    // now we got our planet
    var planet = {name: 'Pluto'}
    component.el.innerHTML = '<div data-sprig-component="hello-planet" data-planet="'+planet.name+'"></div>';
    component.scan();
  }, 1000);
  component.el.innerHTML = "Simulating requesting data from server...";
});
```
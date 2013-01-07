(function(window, undefined) {

  /**
   * Parse data-* attributes of element
   */
  var parseAttrs = (function() {
    var dashed2camel = function(dashedStr) {
      return dashedStr.replace(/-(.){1}/g, function(_, c) {
        return c.toUpperCase()
      })
    };
    return function(el) {
      var data = {};
      for (var i = 0, _len = el.attributes.length; i < _len; i++) {
        var attr = el.attributes[i];
        var match = attr.name.match("^data-(.+)");
        if (match) {
          var prop = dashed2camel(match[1]);
          try {
            data[prop] = JSON.parse(attr.value)
          }
          catch (e) {
            data[prop] = attr.value;
          }
        }
      }
      return data;
    }
  })();

  // DOM4 MutationObserver http://dom.spec.whatwg.org/#mutation-observers
  // todo: var MutationObserver = window.MutationObserver || window.WebKitMutationObserver || window.MozMutationObserver;

  var $ = window.jQuery
    || (typeof require == 'function' && require("jquery"))
    || (function() {
    throw "Sprig requires jQuery";
  })();

  var prefix = "sprig";

  var componentAttr = 'data-' + prefix + '-component';
  var readyStateAttr = 'data-' + prefix + '-ready-state';

  //--- Selectors used frequently (todo wrap in a nice chainable api)
  var selectors = {
    component: "[" + componentAttr + "]",
    unprocessed: "[" + componentAttr + "]:not([" + readyStateAttr + "])",
    scheduled: "[" + componentAttr + "][" + readyStateAttr + "=scheduled]",
    deferred: "[" + componentAttr + "][" + readyStateAttr + "=deferred]",
    loading: "[" + componentAttr + "][" + readyStateAttr + "=loading]",
    loaded: "[" + componentAttr + "][" + readyStateAttr + "=loaded]"
  };

  selectors.forComponentDef = function(name) {
    return "[" + componentAttr + "=" + name + "]";
  };

  /**
   * Represents a single component instance
   * @param el element it is attached to
   * @constructor
   * @param parent
   */
  function Component(el, parent) {
    this.$el = $(el);
    this.el = this.$el[0];

    this.params = parseAttrs(this.el);

    // Optional placeholder for data set by middleware/multi initializer (todo)
    this.data = {};

    this.children = [];
    this.parent = parent;
    if (parent) this.parent.children.push(this);

    // Each instance may have their own component definitions
    this.registry = {};
  }

  /**
   * Add a new component to the parent registry
   * @param name
   * @param opts
   * @return {ComponentDef}
   */
  Component.prototype.define = function(name, opts) {
    var myName = this.getName();
    var path = myName ? myName + "." + name : name;

    var componentDef = this.registry[path] = new ComponentDef(path, opts);
    // Scan for deferred occurrences of the newly added component
    var $deferred = this.query(selectors.deferred);
    if ($deferred.length > 0) {
      setTimeout(function() {
        this.load($deferred);
      }.bind(this), 0);
    }
    return componentDef;
  };

  Component.prototype.getName = function() {
    return this.$el.attr("data-sprig-component");
  };

  /**
   * @return {Array}
   */
  Component.prototype.parents = function() {
    var parents = [];
    var it = this.parent;
    while (it && it.parent) {
      parents.push(it);
      it = it.parent;
    }
    return parents;
  };

  Component.prototype.query = function(selector) {
    return this.$el.find(selector);
  };

  /**
   * Scan for uninitialized components
   */
  Component.prototype.scan = function() {
    var $unprocessed = this.query(selectors.unprocessed);
    this.schedule($unprocessed);
    this.load($unprocessed);
    this.children.forEach(function(child) {
      child.scan();
    });
  };

  Component.prototype.schedule = function($elements) {
    $elements.attr("data-sprig-ready-state", 'scheduled');
  };

  Component.prototype.finalize = function() {
    this.$el.attr("data-sprig-ready-state", 'loaded');
    this.scan();
  };

  /**
   * Search for a component definition
   * @param name
   * @return {*}
   */
  Component.prototype.findComponentDef = function(name) {
    var it = this;
    while (it && it.registry) {
      if (it.registry[name]) return it.registry[name];
      it = it.parent;
    }
    return null;
  };

  /**
   * Load child components for elements
   * @param $elements
   */
  Component.prototype.load = function($elements) {
    $elements.attr("data-sprig-ready-state", 'loading');
    var _this = this;
    var groups = $elements.toArray().reduce(function(groups, el) {
      var $el = $(el);
      var componentName = $el.attr("data-sprig-component");
      if (!_this.findComponentDef(componentName)) {
        // ComponentDef is not (yet) registered
        $el.attr("data-sprig-ready-state", "deferred");
        return groups;
      }
      groups[componentName] || (groups[componentName] = []);
      groups[componentName].push(new Component(el, _this));
      return groups;
    }, {});

    for (var componentName in groups) if (groups.hasOwnProperty(componentName)) {
      var components = groups[componentName];
      var componentDef = _this.findComponentDef(componentName);
      if (componentDef.multiInitializer) {
        componentDef.multiInitializer(components);
      }
      components.forEach(function(component) {
        if (componentDef.initializer) componentDef.initializer(component);
        if (!componentDef.loadAsync) component.finalize();
      });
    }
  };

  function ComponentDef(name, opts) {
    this.opts = opts || {};
    this.name = name;

    // Initializer for multiple elements
    this.initializer = null;

    // Initializer for single elements
    this.multiInitializer = null;

    this.loadAsync = false;
  }

  ComponentDef.prototype.init = function(func) {
    this.initializer = func;
    return this;
  };

  ComponentDef.prototype.initMulti = function(func) {
    this.multiInitializer = func;
    return this;
  };

  ComponentDef.prototype.initMany = function(func) {
    console.warn("Use Sprig.define(\""+this.name+"\").initMulti([function]) instead of Sprig.define(\""+this.name+"\").initMany([function])")
    return ComponentDef.prototype.initMulti.apply(this, arguments)
  };

  ComponentDef.prototype.initEach = function() {
    console.warn("Use Sprig.define(\""+this.name+"\").init([function]) instead of Sprig.define(\""+this.name+"\").initEach([function])")
    ComponentDef.prototype.init.apply(this, arguments)
  };

  ComponentDef.prototype.async = function() {
    this.loadAsync = true;
    return this;
  };

  var Sprig = new Component($('html'));

  Sprig.Component = Component;

  if (typeof exports !== 'undefined') {
    // Export as CommonJS module...
    module.exports = Sprig;
  }
  else {
    // ... or add to to the global object as Sprig
    window.Sprig = Sprig;
  }
}(typeof window != 'undefined' ? window : this));
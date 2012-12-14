(function (window, undefined) {

  // DOM4 MutationObserver http://dom.spec.whatwg.org/#mutation-observers
  // todo: var MutationObserver = window.MutationObserver || window.WebKitMutationObserver || window.MozMutationObserver;

  var $ = window.jQuery
      || (typeof require == 'function' && require("jquery"))
      || (function () {
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

  selectors.forComponentDef = function (name) {
    return "[" + componentAttr + "=" + name + "]";
  };

  /**
   * Represents a single component instance
   * @param el element it is attached to
   * @constructor
   * @param parent
   */
  function Component(el, parent) {
    this.el = el;
    this.$el = $(el);
    this.params = el.dataset;

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
  Component.prototype.define = function (name, opts) {
    var componentDef = this.registry[name] = new ComponentDef(name, opts);

    // Scan for deferred occurrences of the newly added component
    var $deferred = this.query(selectors.deferred);
    if ($deferred.length > 0) {
      setTimeout(function () {
        this.load($deferred);
      }.bind(this), 0);
    }
    return componentDef;
  };

  Component.prototype.query = function (selector) {
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

  Component.prototype.schedule = function ($elements) {
    $elements.attr("data-sprig-ready-state", 'scheduled');
  };

  Component.prototype.finalize = function () {
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
  Component.prototype.load = function ($elements) {
    $elements.attr("data-sprig-ready-state", 'loading');
    var _this = this;
    var groups = $elements.toArray().reduce(function (groups, el) {
      var componentName = el.dataset.sprigComponent;
      if (!_this.findComponentDef(componentName)) {
        // ComponentDef is not (yet) registered
        el.dataset.sprigReadyState = 'deferred';
        return groups;
      }
      groups[componentName] || (groups[componentName] = []);
      groups[componentName].push(new Component(el, _this));
      return groups;
    }, {});

    for (var componentName in groups) if (groups.hasOwnProperty(componentName)) {
      var components = groups[componentName];
      var componentDef = _this.findComponentDef(componentName);
      if (componentDef.initializeMany) {
        componentDef.initializeMany(components);
      }
      components.forEach(function (component) {
        if (componentDef.initializeOne) componentDef.initializeOne(component);
        if (!componentDef.loadAsync) component.finalize();
      });
    }
  };

  function ComponentDef(name, opts) {
    this.opts = opts || {};
    this.name = name;

    // Initializer for multiple elements
    this.initializeOne = null;

    // Initializer for single elements
    this.initializeMany = null;

    this.loadAsync = false;
  }

  ComponentDef.prototype.initMany = function (func) {
    this.initializeMany = func;
    return this;
  };

  ComponentDef.prototype.initEach = function (func) {
    this.initializeOne = func;
    return this;
  };

  ComponentDef.prototype.async = function () {
    this.loadAsync = true;
    return this;
  };

  var Sprig = Component;
  var global = new Component($('html'));
  $.extend(Sprig, global);

  // Legacy API - remove when client code has been rewritten ------------------
  Sprig.add = function(name, initializeOne) {
    var async = initializeOne.length > 2;
    var def = Sprig.define(name).initEach(function(component) {
      if (async) {
        initializeOne(component.$el, component.params, function() {
          component.finalize();
        });
      }
      else {
        initializeOne(component.$el, component.params);
        component.finalize();
      }
    });
    if (async) def.async();
  };
  Sprig.load = function($elements) {
    if (!$elements || $elements == $('body')) Sprig.scan();
    else Component.prototype.load.apply(this, arguments);
  };
  // --------------------------------------------------------------------------

  if (typeof exports !== 'undefined') {
    // Export as CommonJS module...
    module.exports = Sprig;
  }
  else {
    // ... or add to to the global object as Sprig
    window.Sprig = Sprig;
  }
}(typeof window != 'undefined' ? window : this));
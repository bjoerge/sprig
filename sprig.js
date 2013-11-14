(function(window, undefined) {

  // Debounces calling of function `f` until current stack frame has cleared.
  // Any subsequent calls of a debounced function will be ignored.
  function debounce(f) {
    var timer;
    return debounced;
    function debounced(){
      if (timer) return;
      timer = setTimeout(function(args) {
        f.apply(this, args); timer = null
      }.bind(this, arguments), 0);
    }
  }

  /**
   * Parse data-* attributes of element
   */
  var dashed2camel = function(dashedStr) {
    return dashedStr.replace(/-(.){1}/g, function(_, c) {
      return c.toUpperCase()
    })
  };

  var getAttrs = function(el) {
    var data = {};
    for (var i = 0, _len = el.attributes.length; i < _len; i++) {
      var attr = el.attributes[i];
      var match = attr.name.match(/^data-(.+)/);
      if (match) {
        var prop = dashed2camel(match[1]);
        data[prop] = attr.value;
      }
    }
    return data;
  };
  var prefix = "sprig";

  var componentAttr = 'data-' + prefix + '-component';
  var readyStateAttr = 'data-' + prefix + '-ready-state';

  //--- Selectors used frequently
  var selectors = {
    component: "[" + componentAttr + "]",
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
    if (Sprig && Sprig.hasOwnProperty('$')) {
      this.$el = Sprig.$(el);
    }
    this.el = el;

    this.params = getAttrs(this.el);

    this.scan = debounce(this.scan);
    this.load = debounce(this.load);
    
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

    this._loadDeferreds();

    return this.registry[path] = new ComponentDef(path, opts);
  };

  Component.prototype._loadDeferreds = function() {
    // Scan for deferred occurrences of the newly added component
    var deferredElements = this.query(selectors.deferred);
    if (deferredElements.length > 0) {
      this.load(deferredElements);
    }
  }
  
  Component.prototype.getName = function() {
    return this.el.getAttribute("data-sprig-component");
  };

  Component.prototype.query = function(selector) {
    return this.el.querySelectorAll(selector);
  };

  /**
   * Scan for uninitialized components
   */
  Component.prototype.scan = function() {
    var allComponents = this.query(selectors.component);
    var unprocessedElements = [];
    for (var i = 0; i < allComponents.length; ++i) {
      var el = allComponents[i];
      if (!el.hasAttribute('data-sprig-ready-state')) {
        unprocessedElements.push(el)
      }
    }
    this.schedule(unprocessedElements);
    this.load(unprocessedElements);
  };

  Component.prototype.schedule = function(elements) {
    for (var i = 0; i < elements.length; ++i) {
      elements[i].setAttribute("data-sprig-ready-state", 'scheduled')
    }
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
   * @param elements
   */
  Component.prototype.load = function(elements) {
    var _this = this;
    var groups = {};
    var el, i, componentName;
    for (i = 0; i < elements.length; ++i) {
      el = elements[i];
      el.setAttribute("data-sprig-ready-state", 'loading')      
      componentName = el.getAttribute("data-sprig-component");
      if (!_this.findComponentDef(componentName)) {
        // ComponentDef is not (yet) registered
        el.setAttribute("data-sprig-ready-state", "deferred");
      }
      else {
        groups[componentName] || (groups[componentName] = []);
        groups[componentName].push(new Component(el, _this));  
      }
    }

    for (componentName in groups) if (groups.hasOwnProperty(componentName)) {
      var components = groups[componentName];
      var componentDef = _this.findComponentDef(componentName);
      if (componentDef.multiInitializer) {
        componentDef.multiInitializer(components);
      }
      components.forEach(function(component) {
        if (componentDef.initializer) componentDef.initializer(component);
        component.el.setAttribute("data-sprig-ready-state", 'loaded')
        component.scan()
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

  }

  ComponentDef.prototype.init = function(func) {
    this.initializer = func;
    return this;
  };

  ComponentDef.prototype.initMulti = function(func) {
    this.multiInitializer = func;
    return this;
  };

  var Sprig = new Component(document.querySelector('html'));

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
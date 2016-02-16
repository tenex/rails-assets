/**
* angular-popeye
* A simple modal library for AngularJS applications

* @author Pathgather <tech@pathgather.com>
* @copyright Pathgather 2015
* @license MIT
* @link https://github.com/Pathgather/popeye
* @version 1.0.5
*/

(function() {
  var angular, popeye,
    bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  popeye = function(angular) {
    "use strict";
    var mod;
    mod = angular.module("pathgather.popeye", []);
    return mod.provider("Popeye", function() {
      var PopeyeProvider;
      return PopeyeProvider = {
        defaults: {
          containerTemplate: "<div class=\"popeye-modal-container\">\n  <div class=\"popeye-modal\">\n    <a class=\"popeye-close-modal\" href ng-click=\"$close()\"></a>\n  </div>\n</div>",
          containerTemplateUrl: null,
          bodyClass: "popeye-modal-open",
          containerClass: null,
          modalClass: null,
          locals: null,
          resolve: null,
          scope: null,
          controller: null,
          keyboard: true,
          click: true
        },
        $get: ["$q", "$animate", "$rootScope", "$document", "$http", "$templateCache", "$compile", "$controller", "$injector", function($q, $animate, $rootScope, $document, $http, $templateCache, $compile, $controller, $injector) {
          var PopeyeModal, currentModal, pendingPromise;
          currentModal = null;
          pendingPromise = null;
          $document.on("keydown", function(evt) {
            if (evt.which === 27 && (currentModal != null) && currentModal.options.keyboard) {
              return currentModal.close({
                reason: "keyboard"
              });
            }
          });
          PopeyeModal = (function() {
            function PopeyeModal(options) {
              if (options == null) {
                options = {};
              }
              this.handleError = bind(this.handleError, this);
              this.close = bind(this.close, this);
              this.open = bind(this.open, this);
              this.resolve = bind(this.resolve, this);
              if (!((options.template != null) || (options.templateUrl != null))) {
                throw new Error("template or templateUrl must be provided");
              }
              this.options = angular.extend(angular.copy(PopeyeProvider.defaults), options);
              this.resolvedDeferred = $q.defer();
              this.resolved = this.resolvedDeferred.promise;
              this.openedDeferred = $q.defer();
              this.opened = this.openedDeferred.promise;
              this.closedDeferred = $q.defer();
              this.closed = this.closedDeferred.promise;
            }

            PopeyeModal.prototype.resolve = function() {
              if (this.resolving) {
                return this.resolved;
              }
              this.resolving = true;
              $q.when({}).then((function(_this) {
                return function() {
                  var locals, resolve;
                  locals = angular.extend({
                    modal: _this
                  }, _this.options.locals);
                  resolve = angular.extend({}, _this.options.resolve);
                  angular.forEach(resolve, function(value, key) {
                    return locals[key] = angular.isString(value) ? $injector.get(value) : $injector.invoke(value, null, locals);
                  });
                  return $q.all(locals);
                };
              })(this)).then((function(_this) {
                return function(resolved) {
                  _this.scope = _this.options.scope != null ? _this.options.scope : $rootScope.$new();
                  _this.scope.$close = function() {
                    return _this.close.apply(_this, arguments);
                  };
                  if (_this.options.controller) {
                    _this.controller = $controller(_this.options.controller, angular.extend({
                      $scope: _this.scope
                    }, resolved));
                  }
                  return _this.resolvedDeferred.resolve(_this);
                };
              })(this), (function(_this) {
                return function(error) {
                  return _this.handleError(error);
                };
              })(this));
              return this.resolved;
            };

            PopeyeModal.prototype.open = function() {
              var promise;
              if (this.opening) {
                return this.opened;
              }
              this.opening = true;
              promise = pendingPromise != null ? pendingPromise = pendingPromise.then((function(_this) {
                return function(prevModal) {
                  return prevModal.close().then(function() {
                    return _this;
                  });
                };
              })(this)) : currentModal != null ? pendingPromise = currentModal.close().then((function(_this) {
                return function() {
                  return _this;
                };
              })(this)) : (pendingPromise = this.opened, $q.when());
              promise.then((function(_this) {
                return function() {
                  return _this.resolve().then(function() {
                    var containerPromise;
                    if (_this.scope == null) {
                      throw new Error("@scope is undefined");
                    }
                    containerPromise = _this.options.containerTemplate != null ? $q.when({
                      data: _this.options.containerTemplate
                    }) : _this.options.containerTemplateUrl != null ? $http.get(_this.options.containerTemplateUrl, {
                      cache: $templateCache
                    }) : $q.reject("Missing containerTemplate or containerTemplateUrl");
                    return containerPromise.then(function(containerTmpl) {
                      var containerElement, templatePromise;
                      containerElement = angular.element(containerTmpl.data);
                      if (_this.options.containerClass) {
                        containerElement.addClass(_this.options.containerClass);
                      }
                      templatePromise = _this.options.template != null ? $q.when({
                        data: _this.options.template
                      }) : _this.options.templateUrl != null ? $http.get(_this.options.templateUrl, {
                        cache: $templateCache
                      }) : $q.reject("Missing containerTemplate or containerTemplateUrl");
                      return templatePromise.then(function(tmpl) {
                        var body, bodyLastChild;
                        angular.element(containerElement[0].querySelector(".popeye-modal")).append(tmpl.data);
                        if (_this.options.click) {
                          containerElement.on("click", function(evt) {
                            if (evt.target === evt.currentTarget) {
                              return _this.close();
                            }
                          });
                        }
                        _this.container = $compile(containerElement)(_this.scope);
                        _this.element = angular.element(_this.container[0].querySelector(".popeye-modal"));
                        if (_this.options.modalClass) {
                          _this.element.addClass(_this.options.modalClass);
                        }
                        body = $document.find("body");
                        if (body[0].lastChild) {
                          bodyLastChild = angular.element(body[0].lastChild);
                        }
                        if (_this.options.bodyClass) {
                          body.addClass(_this.options.bodyClass);
                        }
                        return $animate.enter(_this.container, body, bodyLastChild).then(function() {
                          currentModal = _this;
                          return _this.openedDeferred.resolve(_this);
                        });
                      });
                    });
                  });
                };
              })(this))["catch"]((function(_this) {
                return function(error) {
                  return _this.handleError(error);
                };
              })(this))["finally"](function() {
                return pendingPromise = null;
              });
              return this.opened;
            };

            PopeyeModal.prototype.close = function(value) {
              if (this.closing) {
                return this.closed;
              }
              this.closing = true;
              this.opened.then((function(_this) {
                return function() {
                  if (_this.container == null) {
                    throw new Error("@container is undefined");
                  }
                  return $animate.leave(_this.container).then(function() {
                    currentModal = null;
                    if (!_this.options.scope) {
                      _this.scope.$destroy();
                    }
                    $document.find("body").removeClass(_this.options.bodyClass);
                    return _this.closedDeferred.resolve(value);
                  }, function(error) {
                    return _this.handleError(error);
                  });
                };
              })(this));
              return this.closed;
            };

            PopeyeModal.prototype.handleError = function(error) {
              this.resolvedDeferred.reject(error);
              this.openedDeferred.reject(error);
              return this.closedDeferred.reject(error);
            };

            return PopeyeModal;

          })();
          return {
            openModal: function(options) {
              var modal;
              if (options == null) {
                options = {};
              }
              modal = new PopeyeModal(options);
              modal.open();
              return modal;
            },
            closeCurrentModal: function(value) {
              if (currentModal != null) {
                currentModal.close(value);
              }
              return currentModal;
            },
            isModalOpen: function() {
              return !!currentModal;
            }
          };
        }]
      };
    });
  };

  if ((typeof window !== "undefined" && window !== null ? window.angular : void 0) != null) {
    popeye(window.angular);
  } else if (typeof require === "function") {
    angular = require("angular");
    popeye(angular);
  } else {
    throw new Error("Could not find angular on window nor via require()");
  }

  if (typeof module !== "undefined" && module !== null) {
    module.exports = "pathgather.popeye";
  }

}).call(this);

ComponentController = ($scope, $filter, $http, $routeParams, $controller) ->
  $http.get("/components.json").then (response) ->
    $scope.gem = $filter('filter')(response.data, { name: $routeParams.componentName }, true)[0]
    $controller('SearchResultController', { $scope: $scope })

angular.module('rails-assets').controller 'ComponentController',  [
  '$scope',
  '$filter',
  '$http',
  '$routeParams',
  '$controller',
  ComponentController
]

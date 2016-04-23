ComponentController = ($rootScope, $scope, $filter, $http, $routeParams, $location, $controller) ->
  $scope.$watch 'selectedVersion', ->
    if $scope.selectedVersion?
      versionForRoute = ($scope.selectedVersion unless $scope.gem?.latestVersion == $scope.selectedVersion)
      $location.search(version: versionForRoute)
      $http.get("/components/#{$scope.componentName}/#{$scope.selectedVersion}").then (response) ->
        $scope.javascripts = (path for path in response.data when path.type is 'javascript')
        $scope.stylesheets = (path for path in response.data when path.type is 'stylesheet')
        $scope.jsManifest = (path for path in $scope.javascripts when path.main is true).length > 0
        $scope.cssManifest = (path for path in $scope.stylesheets when path.main is true).length > 0

  $scope.componentName = $routeParams.componentName

  setVersion = -> $scope.selectedVersion = $routeParams.version || $scope.gem?.latestVersion
  $rootScope.$on '$routeUpdate', setVersion
  setVersion()

  $http.get("/components.json").then (response) ->
    $scope.gem = $filter('filter')(response.data, { name: $scope.componentName }, true)[0]
    $controller('SearchResultController', { $scope: $scope })
    setVersion()

  $scope.onClipboardCopy = (event) ->
    event.clearSelection()
    angular.element(event.trigger).addClass('tooltipped')
    true

angular.module('rails-assets').controller 'ComponentController',  [
  '$rootScope',
  '$scope',
  '$filter',
  '$http',
  '$routeParams',
  '$location',
  '$controller',
  ComponentController
]

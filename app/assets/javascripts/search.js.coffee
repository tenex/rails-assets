SearchController = ($scope, $http, $filter, $rootScope, $routeParams, $location, $document) ->
  $scope.limit = 5

  $scope.fetch = ->
    $http.get("/components.json").then (res) ->
      $scope.gems = $filter('orderBy')(res.data, 'name')

      if $scope.gems.length == 1
        $scope.$broadcast 'showAssets'

  $scope.fetch()

  $scope.search =
    name: $routeParams.query

  $scope.$watch 'search.name', (name) ->

    if name
      $scope.limit = 5
      $scope.$broadcast('component.name', name)

      $rootScope.lastSearch = name
      $location.search('query', name).replace()

      if $document.scrollTop() < 480
        $document.scrollTop(480)

  $scope.expand = ->
    $scope.limit = $scope.gems.length

#need to use semver sort
VERSION_PARTS_COMPARE = (a, b) ->
  if a.length == 0 || b.length == 0
    a.length > 0
  else if a[0] != b[0]
    parseInt(a[0]) > parseInt(b[0])
  else
    VERSION_PARTS_COMPARE(a.slice(1), b.slice(1))

SearchResultController = ($scope) ->
  $scope.gem.latestVersion = $scope.gem.versions.sort((versionA, versionB) ->
    versionPartsA = versionA.split('.')
    versionPartsB = versionB.split('.')
    if VERSION_PARTS_COMPARE(versionPartsA, versionPartsB) then 1 else -1
  ).slice(-1)[0]

angular.module('rails-assets').controller 'SearchController',  [
  '$scope',
  '$http',
  '$filter',
  '$rootScope',
  '$routeParams',
  '$location',
  '$document',
  SearchController
]

angular.module('rails-assets').controller 'SearchResultController',  [
  '$scope',
  SearchResultController
]

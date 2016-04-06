app = angular.module('rails-assets', ['semverSort', 'ngNotificationsBar', 'ngAnimate', 'pathgather.popeye'])

app.controller 'GemCtrl', ['$scope', '$http', ($scope, $http) ->
  $scope.javascripts = []
  $scope.stylesheets = []
  $scope.jsManifest = false
  $scope.cssManifest = false

  $scope.fetchAssets = (version) ->
    $http.get("/components/#{$scope.gem.name}/#{version}").then (response) ->
      $scope.javascripts = (path for path in response.data when path.type is 'javascript')
      $scope.stylesheets = (path for path in response.data when path.type is 'stylesheet')
      $scope.jsManifest = (path for path in $scope.javascripts when path.main is true).length > 0
      $scope.cssManifest = (path for path in $scope.stylesheets when path.main is true).length > 0
]

app.controller "ConvertCtrl", ["$scope", "$http", ($scope, $http) ->
  $scope.converting = false
  $scope.component =
    name: null
    version: null

  $scope.error = null

  $scope.$on 'component.name', (event, name) ->
    $scope.component.name = name

  $scope.convert = ->
    $scope.converting = true
    $scope.error = null
    $scope.gem = null

    $http.post("/components", component: $scope.component).success((data, xhr) ->
      $scope.gem = data
      $scope.converting = false
    ).error (data, status) ->
      $scope.converting = false
      if status == 302
        $scope.error =
          message: "Package #{component} already exist"
      else
        console.log(data)
        if data?
          $scope.error = data
        else
          $scope.error = "There was an critical error. It was reported to our administrator."
]

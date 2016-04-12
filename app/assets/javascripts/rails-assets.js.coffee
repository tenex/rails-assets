app = angular.module('rails-assets', ['semverSort', 'ngNotificationsBar', 'ngAnimate', 'pathgather.popeye', 'ngRoute'])

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

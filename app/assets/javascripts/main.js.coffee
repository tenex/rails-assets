app = angular.module("app", [])
app.directive "ngHtml", ->
  (scope, element, attrs) ->
    scope.$watch attrs.ngHtml, (value) ->
      element[0].innerHTML = value


app.directive "dependencies", ->
  (scope, element, attrs) ->
    scope.$watch attrs.dependencies, (deps) ->
      html = []

      for dep in deps
        h = "<span class=\"name\">" + dep[0] + "</span>"
        h += "<span class=\"req\"> (" + dep[1] + ")</span>"
        html.push h

      element[0].innerHTML = html.join(", ")


app.controller "IndexCtrl", ["$scope", "$http", ($scope, $http) ->
  $scope.fetch = ->
    $http.get("/components.json").then (res) ->
      $scope.gems = res.data

  $scope.fetch()

  $scope.search =
    name: ""
]

app.controller "ConvertCtrl", ["$scope", "$http", ($scope, $http) ->
  $scope.converting = false
  $scope.component =
    name: null
    version: null

  $scope.error = null

  $scope.convert = ->
    $scope.converting = true
    $scope.error = null
    $scope.gem = null

    $http.post("/components.json", component: $scope.component).success((data, xhr) ->
      $scope.gem = data
      $scope.converting = false
    ).error (data, status) ->
      $scope.converting = false
      if status == 302
        $scope.error =
          message: "Package #{component} already exist"
      else
        $scope.error = data
]

app = angular.module("app", [])
app.directive "ngHtml", ->
  (scope, element, attrs) ->
    scope.$watch attrs.ngHtml, (value) ->
      element[0].innerHTML = value


app.directive "dependencies", ->
  (scope, element, attrs) ->
    scope.$watch attrs.dependencies, (deps) ->
      html = []
      i = 0

      while i < deps.length
        h = "<span class=\"name\">" + deps[i].name + "</span>"
        h += "<span class=\"req\"> (" + deps[i].reqs.join(", ") + ")</span>"
        html.push h
        i++
      element[0].innerHTML = html.join(", ")


app.controller "IndexCtrl", ["$scope", "$http", ($scope, $http) ->
  $scope.fetch = ->
    $http.get("/index.json").then (res) ->
      $scope.gems = res.data

  $scope.fetch()

  $scope.search =
    name: ""

]

app.controller "ConvertCtrl", ["$scope", "$http", ($scope, $http) ->
  $scope.converting = false
  $scope.pkg =
    name: null
    verions: null

  $scope.error = null

  $scope.convert = ->
    $scope.converting = true
    $scope.error = null

    pkg = $scope.pkg.name
    pkg += ("#" + $scope.pkg.version) if $scope.pkg.version

    $http.post("/convert.json", pkg: pkg).success((data, xhr) ->
      console.log "suc", data, xhr
      $scope.converting = false
      $scope.pkg.name = data.gem
    ).error (data, status) ->
      $scope.converting = false
      if status == 302
        $scope.error =
          message: "Package #{pkg} already exist"
      else
        $scope.error = data
]

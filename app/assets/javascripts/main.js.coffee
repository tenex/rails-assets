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


app.controller "MainCtrl", ["$scope", "$http", ($scope, $http) ->
  $scope.reload = ->
    $http.get("/index.json").then (res) ->
      $scope.gems = res.data


  $scope.reload()
  $scope.search =
    name: ""
  $scope.pkg =
    name: null
    converting: false
    success: null
    error: null
    force: false
    open: ->
      $scope.pkg.force = true

    convert: ->
      $scope.pkg.converting = true
      data = pkg: $scope.pkg.name
      data.pkg += ("#" + $scope.pkg.version)  if $scope.pkg.version
      $http.post("/convert.json", data).success((data) ->
        $scope.reload()
        $scope.pkg.success = "Gem #{data.gem} built successfully!"
        $scope.pkg.error = null
        $scope.pkg.converting = false
        $scope.pkg.version = null
        $scope.search.name = $scope.pkg.name
      ).error (data, status) ->
        console.log "error", status, data
        $scope.pkg.converting = false
        $scope.pkg.error = "ERROR: " + data.error
        $scope.pkg.errorLog = data.log
        $scope.pkg.success = null


  $scope.$watch "search.name", (val, old) ->
    $scope.pkg.name = val

]

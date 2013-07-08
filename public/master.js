app = angular.module("app", []);
app.directive('ngHtml', function() {
  return function(scope, element, attrs) {
    scope.$watch(attrs.ngHtml, function(value) {
      element[0].innerHTML = value;
    });
  }
});
app.directive("dependencies", function(){
  return function(scope, element, attrs){
    scope.$watch(attrs.dependencies, function(deps){
      var html = [];
      for(var i=0; i<deps.length; i++){
        h = '<span class="name">' + deps[i].name + '</span>';
        h+= '<span class="req"> (' + deps[i].reqs.join(", ") + ')</span>';
        html.push(h)
      }
      element[0].innerHTML = html.join(", ");
    })
  }
})
app.controller("MainCtrl",
  ["$scope", "$http",
  function($scope, $http){
    $scope.reload = function(){
      $http.get("/index.json").then(function(res){
        $scope.gems = res.data
      })
    };
    $scope.reload();
    $scope.search = {name: ""};
    $scope.pkg = {
      name: null,
      converting: false,
      success: null,
      error: null,
      force: false,
      open: function(){
        $scope.pkg.force = true;
      },
      convert: function(){
        $scope.pkg.converting = true

        data = {pkg: $scope.pkg.name};
        if($scope.pkg.version){
          data.pkg += ("#" + $scope.pkg.version);
        }
        $http.post("/convert.json", data).success(function(data){
          $scope.reload();
          $scope.pkg.success = "Gem " + data.gem + " built successfully!";
          $scope.pkg.error = null;
          $scope.pkg.converting = false;
          $scope.pkg.version = null;
          $scope.search.name = $scope.pkg.name;
        }).error(function(data, status){
          console.log("error", status, data)
          $scope.pkg.converting = false;
          $scope.pkg.error = "ERROR: " + data.error;
          $scope.pkg.errorLog = data.log;
          $scope.pkg.success = null;
        })
      }
    };
    $scope.$watch("search.name", function(val, old){
      $scope.pkg.name = val;
    })
}]);

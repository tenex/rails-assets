HOST="localhost:3000"

for pkg in angular-bootstrap angular-cookies moment-range angular-date-range-picker angular-faye angular-mocks angular-mousewheel hamsterjs angular-resource angular-scenario angular-tagger angular-ui-router angular-ui-select2 select2 angular-ujs angular-unstable bootstrap-datepicker css-modal griddle handlebars jquery.cookie responsive-nav opentip purl resizeend swipe angular-route normalize-css validate-patched classie angular angular-digest-interceptor angular-bootstrap-datetimepicker bootstrap-datetimepicker sugar lodash angular-prevent-default elusive-iconfont underscore jquery bootstrap fastclick jquery-mousewheel leaflet spin.js uglify-js microplugin moment d3 selectize sifter momentjs angular-dragdrop jquery-ui mathjs knockout-semantic sass-bootstrap-glyphicons; do
  echo $pkg
  curl -v http://$HOST/components.json -d "component[name]=$pkg"
done

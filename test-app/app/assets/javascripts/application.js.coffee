#= require jquery
#= require sugar
#= require angular
#= require resizeend
#= require leaflet
#= require jquery.cookie
#= require purl
#= require select2
#= require d3
#= require underscore

assert = (label, cond) ->
  res = false
  try
    res = cond()
  catch e
    ex = e
    res = false

  [cls, text] = if res == "pending"
    ["pending", "PENDING"]
  else if res
    ["ok", "OK"]
  else
    ["error", "ERROR"]

  text += "<br/>" + ex if ex
  $("#results").append("<tr class='#{cls}'><td>#{label}</td><td>#{text}</td></tr>")


$ ->
  assert "sugar", -> "".assign
  assert "angular", -> angular
  assert "resizeend", -> "pending"
  assert "leaflet", ->
    $("body").append("<div id='leaflet-map'/>")
    map = L.map('leaflet-map').setView([51.505, -0.09], 13)

    L.tileLayer('http://{s}.tile.osm.org/{z}/{x}/{y}.png', {
      attribution: '&copy; <a href="http://osm.org/copyright">OpenStreetMap</a> contributors'
    }).addTo(map)

    L.marker([51.5, -0.09]).addTo(map)
      .bindPopup('A pretty CSS3 popup. <br> Easily customizable.')
      .openPopup();

  assert "jquery.cookie", -> $.cookie
  assert "purl", -> purl()
  assert "select2", ->
    $("#select2").select2()
  assert "d3", -> d3.select("body")
  assert "underscore", -> _([1]).map

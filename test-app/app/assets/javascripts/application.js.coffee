#= require jquery
#= require sugar
#= require angular
#= require resizeend
#= require leaflet


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
  assert "leaflet", -> L.map

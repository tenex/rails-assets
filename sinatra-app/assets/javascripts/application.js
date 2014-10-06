//= require jquery
//= require jquery-cookie
//= require angular-bootstrap

$(function() { 
  if($.cookie) {
    alert('All right, jQuery cookie is loaded!')
  } else {
    alert('Something went wrong! jQuery cookie is not loaded!')
  }
});

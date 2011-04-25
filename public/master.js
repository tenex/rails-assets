(function($) {
  $("form.delete-form").submit(function() {
    return confirm("Are you sure you want to delete this gem?");
  });
})(jQuery);

(function(){
  window.DABBLE.pages.Entries_new = window.DABBLE.pages.Entries_create = function(){

    $(".j-image-remove").click(function( event ) {
      $(".j-image-preview").slideToggle();
    });

    $('form').submit(function(){
      $(this).find('input[type=submit]').prop('disabled', true);
      $(this).find('input[type=submit]').addClass('disabled');
    });

  };

}());
      $("dl.decision-tree dd, dl.decision-tree dt").addClass("collapsed");
  $("dl.decision-tree dt").click(function(event) {
  	$(event.target).toggleClass("collapsed");
    $(event.target).next().toggleClass("collapsed");
  });
  

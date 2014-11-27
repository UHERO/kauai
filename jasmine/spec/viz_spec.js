describe("Viz", function(){
  
  it("set up the navigation links", function(){
    var viz = {
       set_up_nav: function(){
         set_up_nav();
       }
     };

     spyOn(viz, "set_up_nav")
    
    expect(viz.set_up_nav).toHaveBeenCalled()
  })
})
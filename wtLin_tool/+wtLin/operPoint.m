classdef operPoint < wtLin.mapAbleStruct
            
      methods (Static)
          function op=wind(wnd)
              op=wtLin.operPoint(); %%Implicit constructor
              op.s.env.wind=wnd;
              op.s.env.airDensity=1.225;
          end
          
        function op=default()
            op=wtLin.operPoint();
            op.s.env.wind=9;
            op.s.env.airDensity=1.225;
            op.s.setPoint.pitch=10;
            op.s.setPoint.genRpm=1000;
            op.s.setPoint.power=3000;
            op.s.ctrl.FL=false;
            op.s.ctrl.EnableTL=true;
    %             op.s.ctrl.ThrustLimit=
        end
                
    end
    
end
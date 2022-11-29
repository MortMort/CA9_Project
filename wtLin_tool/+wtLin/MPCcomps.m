classdef MPCcomps < wtLin.comps %wtLin.mapAbleStruct% wtLIN.comps %
       
    methods (Static)
        function c=calcComps(lp)
            
            c=wtLin.MPCcomps(); %wtLin.MPCcomps();
           
            c.s=c.getCompsFromLp(lp);
            
        end
        
    end
    
    methods (Access=protected)
      function s=getCompsFromLp(c,lp)
            s=getCompsFromLp@wtLin.comps(c,lp);
            lps=lp.s;%LFSLA
             %%Create components
            s.twr=c.getTowerFA(lps.mp.twr);
            s.aeroThrust=c.getAeroDynThrust(lps.mp.aero);
  
            
            %SpdRef->      |FLC->Pit->Aero->|            |RotSpd->
            %Wind->        |                |Drivetrain->|GenSpd-> 
            %GenSpd->Filt->|PLC->Conv->Gen->|            
        end
    end
    
    methods(Access=protected,Static)
     
       function dyn=getTowerFA(twr)
           ftowy=twr.eig; %eig_corr corrected for tower compression
           Dy=twr.Dampy; % Tower fore aft damping
           M=twr.Mass; % Swinging mass 3*Mbl+Mhub+Mnac
           F = [-4*pi*Dy*ftowy,-4*(pi*ftowy)^2;1,0]; 
            G = [1/M;0];
            H = [1,0;0,1];
            J = [0;0]; 
            dyn = ss(F,G,H,J);
            dyn.InputName={'Fthrust'};
            dyn.StateName={'Ta','Tv'};
            dyn.OutputName={'Ta','Tv'};
        end 
        
        function dyn=getAeroDynThrust(aero)
            %Note below is obsolete, only induction lag on dMdw

            %Aerodynamics
            %u: [th;v;w_LSS]
            %x: Mrot
            %y: Mrot
            F = 0; 
            G = [0 0 0];
            H = 0;%1;
            J = [aero.dF.dth, aero.dF.dv aero.dF.dw]; 
            dyn = ss(F,G,H,J);

            dyn.InputName={'th','v','W'};
            dyn.StateName='Fthrust';
            dyn.OutputName='Fthrust';
        end
    end
    
    
end
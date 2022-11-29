classdef MPCloops < wtLin.loops
       
    methods (Static)
        function loop=calcLoops(comp)
           loop=wtLin.MPCloops();
           loop.s=loop.getLoopsFromComps(comp);           
        end
    end
    
    methods (Access=protected)
         function s=getLoopsFromComps(l,comp)
           
           s=getLoopsFromComps@wtLin.loops(l,comp);
             
           c=comp.s;
           %System Model 
           s.FLC_MDL=connect(c.drt,c.aeroFLC,comp.one('P_ref','Pconv'),c.gen,comp.one('th_ref','th'),'th_ref','w');
           s.PLC_MDL=connect(c.drt,c.aeroFLC,comp.one('P_ref','Pconv'),c.gen,comp.one('th_ref','th'),'P_ref','w');
           
           s.MIMO_MDL=connect(c.drt,c.aeroFLC,comp.one('P_ref','Pconv'),c.gen,comp.one('th_ref','th'),{'th_ref','P_ref','v'},{'w'});
           
           Sum_twr = sumblk('v','vfree','Tv','+-');
           s.MIMO_MDLwTWR=connect(c.drt,c.aeroFLC,comp.one('P_ref','Pconv'),c.gen,comp.one('th_ref','th'),c.aeroThrust,c.twr,Sum_twr,{'th_ref','P_ref','vfree'},{'Ta','Tv','w'});
           
         end
    end
    
end
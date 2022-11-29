classdef loops < wtLin.mapAbleStruct
       
    methods (Static)
        function loop=calcLoops(comp)
           c=comp.s;
           loop=wtLin.loops();
           Sum_wRef_wFilt = sumblk('e','wRef','wFilt','+-');
           Sum_wRef_w = sumblk('e','wRef','w','+-');
           
           w = warning; % Get warning handle
           warning('off'); % Turn off all to avoid warnings for unused inputs/outputs.
           
           % CL wRef->w, no Tower
           loop.s.FLC_CL_wRef2w_nT = connect(c.FBfilt,c.FLC,c.drt,c.aeroFLC,c.cnv,c.gen,c.pit,Sum_wRef_wFilt,'wRef','w');
           loop.s.PLC_CL_wRef2w_nT = connect(c.FBfilt,c.PLC,c.drt,c.aeroPLC,c.cnv,c.gen,c.pit,Sum_wRef_wFilt,'wRef','w');
           
           % CL wRef->w, no Tower, no Bs Filters
           loop.s.FLC_CL_wRef2w_nT_nf = connect(c.FLC,c.drt,c.aeroFLC,c.cnv,c.gen,c.pit,Sum_wRef_w,'wRef','w');
           loop.s.PLC_CL_wRef2w_nT_nf = connect(c.PLC,c.drt,c.aeroPLC,c.cnv,c.gen,c.pit,Sum_wRef_w,'wRef','w');

           % CL wRef->w
           loop.s.FLC_CL_wRef2w = connect(c.FBfilt,c.FLC,c.drt,c.aeroFLC,c.cnv,c.gen,c.pit,Sum_wRef_wFilt,...
               c.FATD,c.aeroThr,c.rotWind,c.towSprMassFa,'wRef','w');
           loop.s.PLC_CL_wRef2w = connect(c.FBfilt,c.PLC,c.drtSs,c.aeroPLC,c.cnv,c.gen,c.pit,Sum_wRef_wFilt,...
               c.towSprMassSs,'wRef','w');
           
           % CL vfree->w, no Tower
           loop.s.FLC_CL_vfree2w_nT = connect(c.FBfilt,c.FLC,c.drt,c.aeroFLC,c.cnv,c.gen,c.pit,c.rotWind,Sum_wRef_wFilt,'vfree','w');
           loop.s.PLC_CL_vfree2w_nT = connect(c.FBfilt,c.PLC,c.drt,c.aeroPLC,c.cnv,c.gen,c.pit,c.rotWind,Sum_wRef_wFilt,'vfree','w');
           
           % CL vfree->w
           loop.s.FLC_CL_vfree2w = connect(c.FBfilt,c.FLC,c.drt,c.aeroFLC,c.cnv,c.gen,c.pit,Sum_wRef_wFilt,...
               c.FATD,c.aeroThr,c.rotWind,c.towSprMassFa,'vfree','w');
           loop.s.PLC_CL_vfree2w = connect(c.FBfilt,c.PLC,c.drtSs,c.aeroPLC,c.cnv,c.gen,c.pit,Sum_wRef_wFilt,...
               c.rotWind,c.towSprMassSs,'vfree','w');

           % CL vfree->vy,vWy
           loop.s.FLC_CL_vfree2vy = connect(c.FBfilt,c.FLC,c.drt,c.aeroFLC,c.cnv,c.gen,c.pit,Sum_wRef_wFilt,...
               c.FATD,c.aeroThr,c.rotWind,c.towSprMassFa,'vfree','vy');
           loop.s.PLC_CL_vfree2vWx = connect(c.FBfilt,c.PLC,c.drtSs,c.aeroPLC,c.cnv,c.gen,c.pit,Sum_wRef_wFilt,...
               c.rotWind,c.towSprMassSs,'vfree','vWy');
           
           % OL e->w, no Tower
           loop.s.FLC_OL_e2w_nT = connect(c.FBfilt,c.FLC,c.drt,c.aeroFLC,c.cnv,c.gen,c.pit,'e','w');
           loop.s.PLC_OL_e2w_nT = connect(c.FBfilt,c.PLC,c.drt,c.aeroPLC,c.cnv,c.gen,c.pit,'e','w');
                     
           % OL e->w
           loop.s.FLC_OL_e2w = connect(c.FBfilt,c.FLC,c.drt,c.aeroFLC,c.cnv,c.gen,c.pit,...
               c.FATD,c.aeroThr,c.rotWind,c.towSprMassFa,'e','w');
           loop.s.PLC_OL_e2w = connect(c.FBfilt,c.PLC,c.drtSs,c.aeroPLC,c.cnv,c.gen,c.pit,...
               c.rotWind,c.towSprMassSs,'e','w');
                      
           % CL wNoise->w, no Tower, Noise on generator speed
           Sum_wNoise = sumblk('wPlusNoise','w','wNoise','++');
           FB=c.FBfilt;
           FB.InputName='wPlusNoise';
           loop.s.FLC_CL_wNoise2w_nT = connect(FB,Sum_wNoise,c.FLC,c.drt,c.aeroFLC,c.cnv,c.gen,c.pit,Sum_wRef_wFilt,'wNoise','w');
           loop.s.PLC_CL_wNoise2w_nT = connect(FB,Sum_wNoise,c.PLC,c.drt,c.aeroPLC,c.cnv,c.gen,c.pit,Sum_wRef_wFilt,'wNoise','w');
           
           warning(w); % Enable warnings
                                 
        end
    end
    
end
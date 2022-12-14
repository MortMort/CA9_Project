function runVstabNormalOperation(simpath,ArgIn)
addpath('w:\ToolsDevelopment\VStab\CURRENT\Matlab_version\');

ArgVStab=LAC.vstab.prepvstab(simpath);
v2struct(ArgVStab)

if nargin==2
    v2struct(ArgIn)
end



[Res,Info,Turbgeom,Flow,SSMod]=VStab2(runname,masfn,profiles,usrcfg,exprop,...
            flags,numeig,azi_intervals,vexp,dstype,dsconsts,keepstations,...
            Ws,Pit,Azimuth,phidir,rotationspeed,inout);

save(fullfile(simpath,[runname '.mat']),'Res','Info','Turbgeom','Flow','SSMod');

% Animode(Res,Info,Turbgeom,Flow);
% CampbellGUI(Res,Info);
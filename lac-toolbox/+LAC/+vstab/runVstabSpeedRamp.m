function runVstabSpeedRamp(simpath,windspeed,ArgIn)
addpath('W:\ToolsDevelopment\VStab\CURRENT\SOURCE\')
ArgVStab=prepVStab(simpath,windspeed);
exchange.v2struct(ArgVStab)

if nargin==3
    exchange.v2struct(ArgIn)
end



[Res,Info,Turbgeom,Flow,SSMod]=VStab2(runname,masfn,profiles,usrcfg,exprop,...
            flags,numeig,azi_intervals,vexp,dstype,dsconsts,keepstations,...
            Ws,Pit,Azimuth,phidir,rotationspeed,inout);

save(fullfile(simpath,[runname '.mat']),'Res','Info','Turbgeom','Flow','SSMod');

% Animode(Res,Info,Turbgeom,Flow);
% CampbellGUI(Res,Info);
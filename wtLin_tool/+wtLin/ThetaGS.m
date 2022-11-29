function [gain,gainLin,gainSens] = ThetaGS(g,o,stat,theta)
%Computes the pitch dependent gain for the FLC
%
% Version history
% V0 - 24-04-2012 - JADGR
% V1 - 16-08-2017 - JSTHO (online sensitivity added)

%%
flc = g.ctr.flc;


%% Gain scheduling - linear approximation
if theta < flc.Theta_v    
    gainLin = 1;
else
    gainLin = ...
            (flc.BasedPdTeta + flc.Theta_v * flc.SlopedPdTeta)./ ...
            (flc.BasedPdTeta + theta * flc.SlopedPdTeta); 
end


%% Gain scheduling - online sensitivity

dd=wtLin.aerodiff(stat.lambda,theta,g.aero);
Arot=g.rot.radius^2*pi;
rho=o.env.airDensity;
radius=g.rot.radius;
dMdth = rho/2*Arot * radius * o.env.wind^2 * dd.dcM.dth;

dMdth_Nm_rad = dMdth * 180/pi; % convert to Nm/rad
pit2TrqSens = min(-1000,dMdth_Nm_rad);
pit2TrqSensRatio = flc.TrqSens.NomPit2TrqSens / pit2TrqSens;

gainSensTmp = min(flc.TrqSens.UpPit2TrqSens,pit2TrqSensRatio);
gainSens = max(flc.TrqSens.LoPit2TrqSens,gainSensTmp);

%% Select type

if flc.EnableRotMomentOnlineGainSch > 0.5
    gain = gainSens;
else
    gain = gainLin;
end




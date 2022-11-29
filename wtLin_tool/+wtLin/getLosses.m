function [Ploss,dPm,etaA,etaE,etaM]=getLosses(Pout,wgen,gen)
%Interpolate effeciency factors to compute losses at a given operating
%point

% Version history – Responsible JADGR
% V0 - 24-04-2012 - JADGR

import wtLin.interp2ep;

%Auxiliary effeciency
if (~isfield(gen,'AuxLossEnabled') )%&& gen.AuxLossEnabled)
    etaA_Init=interp2ep(gen.AuxLoss.power,gen.AuxLoss.rpm,gen.AuxLoss.data,Pout,wgen);
    etaA=fzero(@auxEff,etaA_Init);
    [dAdP,dAdw]=gradient(gen.AuxLoss.data,gen.AuxLoss.power,gen.AuxLoss.rpm);
    Pel=Pout/etaA;
    detaAdw=interp2ep(gen.AuxLoss.power,gen.AuxLoss.rpm,dAdw,Pel,wgen);
    detaAdP=interp2ep(gen.AuxLoss.power,gen.AuxLoss.rpm,dAdP,Pel,wgen);
else
    etaA=1;
    dAdP=0;
    dAdw=0;
    Pel=Pout/etaA;
    detaAdw=0;
    detaAdP=0;
end


%Interpolate 


%Mechanical effeciency
etaM=interp2ep(gen.MechEff.power,gen.MechEff.rpm,gen.MechEff.data,Pel,wgen);
[dMdP,dMdw]=gradient(gen.MechEff.data,gen.MechEff.power,gen.MechEff.rpm);
detaMdw=interp2ep(gen.MechEff.power,gen.MechEff.rpm,dMdw,Pel,wgen);
detaMdP=interp2ep(gen.MechEff.power,gen.MechEff.rpm,dMdP,Pel,wgen);

%Electrical effeciency
etaE=interp2ep(gen.ElecEff.power,gen.ElecEff.rpm,gen.ElecEff.data,Pel,wgen);
[dEdP,dEdw]=gradient(gen.ElecEff.data,gen.ElecEff.power,gen.ElecEff.rpm);
detaEdw=interp2ep(gen.ElecEff.power,gen.ElecEff.rpm,dEdw,Pel,wgen);
detaEdP=interp2ep(gen.ElecEff.power,gen.ElecEff.rpm,dEdP,Pel,wgen);

%Calculate rotor power
Ploss=Pout/(etaE*etaM*etaA)-Pout;

%d(Pout/eta).dP=(eta-Pout*deta.dP)/eta^2
dPm.dP=((etaE*etaM*etaA)-Pout*(etaM*etaE*detaAdw+etaM*detaEdw*etaA+detaMdw*etaE*etaA))/((etaE*etaM*etaA)^2); 

%d(Pout/eta).dw=-Pout*deta.dw/eta^2
dPm.dw=-Pout*(etaM*etaE*detaAdP+etaM*detaEdP*etaA+detaMdP*etaE*etaA)/((etaE*etaM*etaA)^2); 
    

function err=auxEff(eta)
     Pel=Pout/eta;
     err=(wtLin.interp2ep(gen.AuxLoss.power,gen.AuxLoss.rpm,gen.AuxLoss.data,Pel,wgen)-eta);
    end
    
end
function [WTG]=WTGSettingEst(D,PowR,OmegaR,OmegaMin,TIref,aero,Ftmax,Eff,TiMode,windSpeedVector,airDensity)

%   D: rotor diameter [m]
%   PowR: rated power [kW]
%   OmegaR: rated rotor speed [rpm]
%   OmegaMin: minimum rotor speed [rpm]
%   TIref: reference turbulence [-] e.g. A=0.16, B=0.14 etc.
%   aero: structure containing aero.cp, aero.ct, aero.lambda, aero.theta
%   Ftmax: maximum thrust [kN]
%   Eff: drive train effecieny i.e combined mech and elec effeciency
%   windSpeedVector: vector of wind speeds to be evaluated [m/s] (default 3:0.2:25)
%	airDensity: air density to be used [kg/m^3] (default 1.225)

aero.theta = aero.theta';
aero.cp    = aero.cp';


Ftmax     = Ftmax*1E3; % thrust to N
PowR      = PowR*1E3;  % power to W
A         = D^2/4*pi;  % rotor area
if ~(exist('windSpeedVector','var') == 1)
    V         = 3:0.2:25; % Wind speed
else
    V = windSpeedVector;
end

if ~(exist('airDensity','var') == 1)
    rho       = 1.225;  % Air density [kg/m3]
else
    rho       = airDensity; 
end


if nargin<9
    TiMode    = 1; %IEC shape turb =1, const turb=0
end
switch TiMode
    case 0
        TI=TIref*ones(length(V),1)';
    case 1
        TI=TIref*(0.75*V+5.6)./V;
end
sigmaV=TI.*V;

% LambdaOpti = [ 1.0  3.0  4.0 5.5 6.5 7.5 8.0 8.5 9.0 9.35 9.9 11.3 13.19 15.0];
% PiOpti = [40.0 17.5 12.5 8.3 6.5 5.2 4.5 4.0 3.5 3.3  3.0  3.6  4.9   5.7];
% LambdaOpt = 9.9; %Optimal lambda
LambdaOpti  = aero.optitipX;
PiOpti      = aero.optitipY;
LambdaOpt   = aero.optilambda;

PiOpt=interp1(LambdaOpti,PiOpti,LambdaOpt); %Optimal pitch
CpOpti=interp2(aero.lambda,aero.theta,aero.cp,LambdaOpti,PiOpti);

%%% Speed curve %%%
Omega=LambdaOpt*V/(D*pi)*60; %Optimal rotor speed
I=find(Omega<OmegaMin);
Omega(I)=OmegaMin;              %Limit on low RPM
I=find(Omega>OmegaR);
Omega(I)=OmegaR;                %Limit on high RPM
Lambda=Omega/60*D*pi./V;

%%% Power curve %%%
Cp=interp1(LambdaOpti,CpOpti,Lambda,'linear','extrap');
Cp(isnan(Cp)) = 0.45;
Pow=0.5*Cp*rho.*V.^3*D^2/4*pi*Eff;
I=find(Pow>PowR);               %Limit on max power
Pow(I)=PowR;
Cp=2*Pow./(A*V.^3*rho);
PowAero=Pow/Eff;
CpAero=2*PowAero./(A*V.^3*rho);
% aero.cp
% aero.lambda

%%% Pitch curve %%%
for i=1:length(V)
    I=find(aero.lambda>=min(Lambda(i),max(aero.lambda)));
    
    %%% Creating Cp vector for specific lambda value
    for j=1:length(aero.theta)
        Cptmp(j)=(aero.cp(j,I(1))-aero.cp(j,I(1)-1))/(aero.lambda(I(1))-aero.lambda(I(1)-1))...
            *(Lambda(i)-aero.lambda(I(1)-1))+aero.cp(j,I(1)-1);
    end
    
    %%% Finding pitch matching lambda and Cp %%%
    for j=1:length(Cptmp)-1;
        if Cptmp(j)>=CpAero(i) & Cptmp(j+1)<CpAero(i)
            Pi(i)=interp1([Cptmp(j) Cptmp(j+1)],[aero.theta(j) aero.theta(j+1)],CpAero(i));
            check=1;
        end
    end
    if ~exist('check') %%% If calculated Cp is above what is defined in Cp table
        Pi(i)=PiOpt;
    end
    clear check Cptmp
end
%%

Ct=interp2(aero.theta,aero.lambda,aero.ct,Pi,Lambda);
Fthr=(0.5*Ct*A*rho.*V.^2);
[FthrTi sigmaFthr]=LAC.climate.addturbulence(Fthr, V, D, TI,1);
FthrTiMax=FthrTi+3.0*sigmaFthr;

% if Ftmax~0  %Limiting thrust (thrust limiter)
%     FthrTiMax(FthrTiMax>Ftmax)=Ftmax;
%     for i=1:length(V)
%         tmp=[-10:0.1:10]*sigmaFthr(i)+FthrTi(i);
%         dF=diff(tmp);
%         pFthrTi=LAC.statistic.normalpdf(tmp,FthrTi(i),sigmaFthr(i));
%         pFthrTi
%         tmp
%         tmp(tmp>Ftmax)=Ftmax;
%         FthrTi(i)=sum(tmp.*pFthrTi*dF(i))
%         
%         
%         
%     end
% end
% for i=1:length(V)
%     Ct(i)=2*FthrTi(i)/(A*rho*V(i)^2);
%     Pi(i)=interp_table(aero.lambda,aero.theta,aero.ct',Lambda(i),Ct(i));
%     Cp(i)=interp2(aero.lambda,aero.theta,aero.cp,Lambda(i),Pi(i));
%     
%     Pow(i)=0.5*Cp(i)*rho*V(i)^3*D^2/4*pi*Eff;
% end
% dCt=diff(Ct)./diff(V);
% % dCt
% % sigmaV
% dCt(end+1)=dCt(end)
% FthrTiMax=FthrTi+3.5*sqrt(0.5^2*rho^2*A^2*(2*Ct.*V+dCt.*V.^2).^2.*sigmaV.^2);

% PowTi=Pow;
% PiTi=Pi;
PowTi   =   LAC.climate.addturbulence(Pow, V, D, TI,1);
PiTi    =   LAC.climate.addturbulence(Pi, V, D, TI,1);
OmegaTi =   LAC.climate.addturbulence(Omega, V, D, TI,1);

I=find(Pow==PowR);
WTG.Vrat=V(I(1));
WTG.D=D;
WTG.PowR=PowR;
WTG.OmegaR=OmegaR;
WTG.FthrTi=FthrTi;
WTG.FthrTiMax=FthrTiMax;
WTG.Fthr=Fthr;
WTG.Pow=Pow;
WTG.PowTi=PowTi;
WTG.Omega=Omega;
WTG.OmegaTi=OmegaTi;
WTG.Pi=Pi;
WTG.PiTi=PiTi;
WTG.V=V;

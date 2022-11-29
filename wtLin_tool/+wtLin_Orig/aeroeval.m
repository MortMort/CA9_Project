%AEROEVAL Evaluation of the aerodynamic torque and thrust
%
%   Syntax: out = aeroeval(vwind,rpm,rho,fmp,Pref,teta,opt)
%
%   Inputs:   vwind     [m/s]     setpoint wind speed [m/s]
%             rpm                 setpoint generator rpm
%             rho       [kg/m^3]  air density
%             fmp       (struct)  free model parameters
%             Pref      [kW]      rotor power reference
%             teta      [deg]     pitch angle (optional)
%             opt       char      'diff': Calculate differentials
%   Output:   out       (struct)  model parameters for the setpoint
%               OptiTip [-]       1 = pitch angle is optimal
%               lambda  [-]       tip speed ratio
%               theta   [deg]     pitch angle
%               MR      [Nm]      rotor torque
%               FT      [N]       rotor thrust
%
%   Method:   The evaluation is carried out for the (lambda,theta) setpoint
%             given by vwind, rpm and Pref. If the teta argument is not passed,
%             the pitch angle is either set to the optimum pitch angle or 
%             to the pitch angle that limits the rotor power to Pref
%
%   See also: AEROLIN

% Version history – Responsible THK/JADGR
% V0 - 01-10-1999 – THK


function out = aeroeval(vwind,rpm,rho,fmp,Pref,teta,opt)

if nargin < 7; opt = 'norm'; end

Arot = pi*fmp.rot.radius^2;
omrot = pi/30 * rpm/fmp.drv.gear_ratio;
radius = fmp.rot.radius;
lambda_tab = fmp.rot.lambda_tab;
theta_tab = fmp.rot.theta_tab;
cp_tab = fmp.rot.cp;

%Find the optimum pitch angle
thopt = optitip(lambda_tab,theta_tab,cp_tab);
lambda = radius * omrot / vwind;
theta_opt = spline(lambda_tab,thopt,lambda);

% Limit optimum pitch angle to minimum pitch angle in thopt.
if theta_opt < min(thopt)
    theta_opt = min(thopt);
end


theta_max = max(fmp.rot.theta_tab);

if (nargin < 6) | isempty(teta)
    Perr = inline('rotpower(theta,vwind,omrot,rho,radius,cp_tab,lambda_tab,theta_tab) - Pref', ...
        'theta','vwind','omrot','rho','radius','cp_tab','lambda_tab','theta_tab','Pref');
    Prot_max = rotpower(theta_opt,vwind,omrot,rho,radius,cp_tab,lambda_tab,theta_tab);
    if Prot_max >= Pref
        teta = fzero(Perr,[theta_opt theta_max], optimset('disp','off'), ...
            vwind,omrot,rho,radius,cp_tab,lambda_tab,theta_tab,Pref);
        out.OptiTip = 0;
    else
        teta = theta_opt;
        out.OptiTip = 1;
    end
end

%Derivation of aerodynamic torque and thrust
dd = interpcp(lambda,teta,fmp,opt);

out.lambda = lambda;
out.theta = teta;
out.MR = rho/2*Arot * fmp.rot.radius * vwind^2 * dd.cM;
out.FT = rho/2*Arot * vwind^2 * dd.cT;
if nargin < 6
    if ~out.OptiTip
        out.MR = 1000 * Pref / omrot;
    end
end

if strcmp(opt,'diff')
    out.dMdv = rho/2*Arot * fmp.rot.radius * vwind * (2*dd.cM - lambda*dd.dcMdl);
    out.dMdom = rho/2*Arot * fmp.rot.radius^2 * vwind * dd.dcMdl;
    out.dMdth = rho/2*Arot * fmp.rot.radius * vwind^2 * dd.dcMdth;
    out.dFdv = rho/2*Arot * vwind * (2*dd.cT - lambda*dd.dcTdl);
    out.dFdom = rho/2*Arot * fmp.rot.radius * vwind * dd.dcTdl;
    out.dFdth = rho/2*Arot * vwind^2 * dd.dcTdth;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function dd = interpcp(lambda,teta,fmp,opt)

switch opt
    case 'diff'
        lambda_delta = 1;
        theta_delta = 1;
        
        lambda1 = min(lambda+lambda_delta,max(fmp.rot.lambda_tab));
        lambda2 = max(lambda-lambda_delta,min(fmp.rot.lambda_tab));
        theta1 = min(teta+theta_delta,max(fmp.rot.theta_tab));
        theta2 = max(teta-theta_delta,min(fmp.rot.theta_tab));
        
        cM = fmp.rot.cp./(ones(length(fmp.rot.theta_tab),1)*fmp.rot.lambda_tab'); 
        cT = fmp.rot.ct;
        
        dd.cM = interp2(fmp.rot.lambda_tab',fmp.rot.theta_tab,cM,lambda,teta,'spline');
        
        %dcM/dlambda
        cM1 = interp2(fmp.rot.lambda_tab',fmp.rot.theta_tab,cM,lambda1,teta,'spline');
        cM2 = interp2(fmp.rot.lambda_tab',fmp.rot.theta_tab,cM,lambda2,teta,'spline');
        dd.dcMdl = (cM1-cM2)/(lambda1-lambda2);
        
        %dcM/dtheta
        cM1 = interp2(fmp.rot.lambda_tab',fmp.rot.theta_tab,cM,lambda,theta1,'spline');
        cM2 = interp2(fmp.rot.lambda_tab',fmp.rot.theta_tab,cM,lambda,theta2,'spline');
        dd.dcMdth = (cM1-cM2)/(theta1-theta2);
        
        dd.cT = interp2(fmp.rot.lambda_tab',fmp.rot.theta_tab,cT,lambda,teta,'spline');
        
        %dcT/dlambda
        cT1 = interp2(fmp.rot.lambda_tab',fmp.rot.theta_tab,cT,lambda1,teta,'spline');
        cT2 = interp2(fmp.rot.lambda_tab',fmp.rot.theta_tab,cT,lambda2,teta,'spline');
        dd.dcTdl = (cT1-cT2)/(lambda1-lambda2);
        
        %dcT/dtheta
        cT1 = interp2(fmp.rot.lambda_tab',fmp.rot.theta_tab,cT,lambda,theta1,'spline');
        cT2 = interp2(fmp.rot.lambda_tab',fmp.rot.theta_tab,cT,lambda,theta2,'spline');
        dd.dcTdth = (cT1-cT2)/(theta1-theta2);
        
    otherwise
        
        cP = interp2(fmp.rot.lambda_tab',fmp.rot.theta_tab,fmp.rot.cp,lambda,teta,'spline');
        dd.cT = interp2(fmp.rot.lambda_tab',fmp.rot.theta_tab,fmp.rot.ct,lambda,teta,'spline');
        
        dd.cM = cP/lambda;
        
end
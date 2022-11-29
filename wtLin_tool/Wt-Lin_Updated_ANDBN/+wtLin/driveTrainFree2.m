function dyn = driveTrainFree2(drt)


rotInertia = drt.RotInertia;
genInertia = drt.GenInertia;
gearRatio = drt.GearRatio;
eigfrequency = drt.eigfrequency;
torsstiffness = drt.torsstiffness;
torsdamping = drt.torsdamping;
useEigFreq = drt.useEigFreq;



%% Drive train two inertia spring-damper system

%% Parameters

Jrot = rotInertia;
Jgen = genInertia * gearRatio^2; % Inertia at Lss

Jeq = (Jgen*Jrot)/(Jgen+Jrot); % from eig value problem

if useEigFreq > 0.5
    eigfreq = eigfrequency;
else
    eigfreq = (1/(2*pi))*sqrt(torsstiffness/Jeq);
end    

% Compute equivalent stiffness including blades
% Eigenfrequency of a mass spring system is: w=sqrt(K/m) => K=w^2*m
% The mass is the equivalent inertia: Ieq=(Igen*Irot)/(Igen+Irot)
K = (eigfreq*2*pi)^2 * Jeq;

% Conversion logarithmic decrement (dlog) to damping ratio (dratio)
% dratio = 1/sqrt(1+(2*pi/dlog)^2)
dlog = torsdamping;
dratio=1/sqrt(1+(2*pi/dlog)^2);

%disp(['driveTrainFree2: damping ratio = ' num2str(dratio)])

% Conversion from damping ratio (dratio) to damping constant (d)
% 2*dratio*eigOmega*Jeq = d (Rayleigh damping)
d = 2*dratio*(2*pi*eigfreq)*Jeq;


% info
%disp(['driveTrainFree2: Specified eigFrq [Hz] = ' num2str(eigfrequency)])
%disp(['driveTrainFree2: Calc eigFrq [Hz] = ' num2str(eigfreq)])
%disp(['driveTrainFree2: damping ratio = ' num2str(dratio)])

%% State space model

    % LLS reference system
    % u: [Mrot ; Mgen] rotor torgue Lss, gen torque Lss
    % x1: OmegaLss (WLss = W)
    % x2: omegaLss (wLss = w*2*pi/(60*gearRatio))
    % x3: epsilon (wLss to W position diff)
    % y: [W; w]
    %
    % Jrot * dW/dt = -d*(W-wLss) - K*epsilon + Mrot
    % Jgen * dwLss/d = -d*(wLss-W) -K*(-espilon) - Mgen
    % d_epsilon/dt = W - wLss
    %
    F = [-d/Jrot   d/Jrot    -K/Jrot;
         d/Jgen    -d/Jgen   K/Jgen;
         1         -1        0];
    G = [1/Jrot 0; 0 -gearRatio/Jgen; 0 0];
    H = [1 0 0; 0 gearRatio*30/pi 0];
    J = [0 0; 0 0];
    dyn = ss(F,G,H,J);

    dyn.InputName = {'Mrot','Mgen'};
    dyn.OutputName = {'W','w'};



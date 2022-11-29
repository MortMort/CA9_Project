classdef comps < wtLin.mapAbleStruct
       
    methods (Static)
        function c=calcComps(lp)
            lps=lp.s;
            c=wtLin.comps();
            
            % Continuous and discrete version of bandstop filter
            %
            ff = getFBfilter(lps.mp.ctr.sp.bs,0.1); % Ts=0.1
            c.s.FBfilt = ff.filt_c;
            c.s.FBfiltd10Hz = ff.filt_d;
            %
            c.s.PLC=getPLC(lps.mp.ctr.plc);
            c.s.FLC=getFLC(lps.mp.ctr.flc);
            c.s.FATD=getForeAftTowDmp(lps.mp.ctr.fatd);
            %
            c.s.drt=getDrivetrainDyn(lps.mp.drt);
            c.s.drtDmp=getDrivetrainDynDmp(lps.mp.drt);
            c.s.drtSs=getDrivetrainDynSs(lps.mp.drt);
            c.s.drtSsDmp=getDrivetrainDynSsDmp(lps.mp.drt);
            c.s.drtFree2=getDrivetrainDynFree2(lps.mp.drt);
            %
            % Due to model problems, different aerodyn for PLC and FLC
            c.s.aeroPLC=getAeroDynPLC(lps.mp.aero);
            c.s.aeroFLC=getAeroDynFLC(lps.mp.aero);
            %
            c.s.cnv=getConverterDyn(lps.mp.cnv);
            c.s.cnvUn=getConverterDynUnity;
            c.s.cnvDtd=getConverterDtdDyn(lps.mp.cnv);
            c.s.cnvDtdUn=getConverterDtdDynUnity;
            %
            c.s.DTD=getDTD(lps.mp.dtd);
            %
            c.s.gen=getGeneratorDyn(lps.mp.gen);
            %
            c.s.pit=getPitchDyn(lps.mp.pit);
            c.s.pitUn=getPitchDynUnity;            
            c.s.aeroThr=getAeroDynThrust(lps.mp.aero);
            c.s.rotWind=getRotorWind;
            %
            c.s.towSprMassFa=getTowerSpringMassFa(lps.mp.twr);
            c.s.towSprMassSs=getTowerSpringMassSs(lps.mp.twr);            
            %            %
            c.s.rotDmpFLC = getPowRotDampFLC(lps.mp.ctr.flc);    
            %
            %c.s.KalmanTowerFa = getKalmanTowerFa(lps.mp.towSprMass);
            %
            %            
        end
    end
    
end


function ff=getFBfilter(bs,Ts)
    ff.filt_c = 1;
    ff.filt_d = 1;
    fld=fields(bs);
    for k=1:length(fld)  
        if(bs.(fld{k}).Enable)
            cc = getBandStopFilter(bs.(fld{k}).FC,bs.(fld{k}).BW,Ts);
            ff.filt_c = ff.filt_c * cc.filt_c; % continuous filter
            ff.filt_d = ff.filt_d * cc.filt_d; % discrete filter
        end
    end
    %dyn=tf2ss(dyn.num{1},dyn.den{1});
    ff.filt_c.InputName='w';
    ff.filt_c.OutputName='wFilt';
    ff.filt_d.InputName='w';
    ff.filt_d.OutputName='wFilt';    
end


function cc = getBandStopFilter(fc,bw,Ts)
    if 0 % original method
        [num1,den1,num2,den2] = wtLin.bsfilt(fc-bw/2,fc+bw/2,Ts);
        Bs1=tf(num1,den1,Ts);
        Bs2=tf(num2,den2,Ts);
        BS = Bs1*Bs2;
        cc.filt_d = BS;
        cc.filt_c = d2c(BS,'matched');
    else % Bs filter as is in turbine code
        [numd,dend,numc,denc,err] = wtLin.prewarpCutOffFrqs(fc,bw,Ts);
        filtBs_c = tf([numc(1) numc(2) numc(3) numc(4) numc(5)],...
            [denc(1) denc(2) denc(3) denc(4) denc(5)]);
        filtBs_d = tf([numd(1) numd(2) numd(3) numd(4) numd(5)],...
            [dend(1) dend(2) dend(3) dend(4) dend(5)],Ts);
        %cc.filt_c = filtBs_c; % presently, cont filter does not work...???
        cc.filt_c = d2c(filtBs_d,'prewarp',2*pi*fc);
        cc.filt_d = filtBs_d;
    end
    
end


function PI=getPI(ctr)
    PI = ctr.Kp*tf([ctr.Ti 1],[ctr.Ti 0]);% PI controller
    %sys.num
    %sys.den
    %PI=tf2ss(sys.num{1},sys.den{1});
end


%PLC controller
function dyn=getPLC(plc)
    dyn=getPI(plc);    
    %Scale references from kW to W
    dyn=dyn*1000;
    dyn.InputName='e';
    dyn.OutputName='Pref';
end


%FLC controller
function dyn=getFLC(flc)
    dyn=getPI(flc);
    dyn.InputName='e';
    dyn.OutputName='thRef';
end



% Fore Aft Tower Damping
function dyn=getForeAftTowDmp(fatd)
    %
    Kp = fatd.Kpos;
    Kv = fatd.Kvel;
    %
    F = 0;
    G = [0 0];
    H = 0;
    J = [Kp Kv];            
    dyn = ss(F,G,H,J);
    %
    dyn.InputName = {'py','vy'};
    %dyn.StateName = '';
    dyn.OutputName = 'thFatd';
end


%%Stiff drivetrain dynamics
function dyn=getDrivetrainDyn(drt)
    %  Rotor inertia at low speed side 
    Jrot = drt.RotInertia;
    % Generator inertia at low speed side
    Jgen_hss = drt.GenInertia;
    Jgen_lss = Jgen_hss*drt.GearRatio^2;
    % Total inertia includes blade inertia and hub inertia
    Jtot = Jrot + Jgen_lss;
    
    % LLS reference system
    % u: [Mrot ; Mgen]
    % x1: OmegaLSS  
    % y: [OmegaLSS; omegaHSS]
    F = 0; 
    G = (1/Jtot)*[1  -1];
    H = [1; drt.GearRatio*30/pi];
    J = [0 0 ; 0 0]; 
    dyn = ss(F,G,H,J);
   
    dyn.InputName={'Mrot','Mgen'};
    dyn.StateName='W';
    dyn.OutputName={'W','w'};
end


%%Stiff drivetrain dynamics
function dyn=getDrivetrainDynDmp(drt)
    %  Rotor inertia at low speed side 
    Jrot = drt.RotInertia;
    % Generator inertia at low speed side
    Jgen_hss = drt.GenInertia;
    Jgen_lss = Jgen_hss*drt.GearRatio^2;
    % Total inertia includes blade inertia and hub inertia
    Jtot = Jrot + Jgen_lss;
    
    % LLS reference system
    % u: [Mrot ; Mgen]
    % x1: OmegaLSS  
    % y: [OmegaLSS; omegaHSS]
    F = 0; 
    G = (1/Jtot)*[1  -1  -1];
    H = [1; drt.GearRatio*30/pi];
    J = [0 0 0; 0 0 0]; 
    dyn = ss(F,G,H,J);
    
    dyn.InputName={'Mrot','Mgen','dmpMgen'};
    dyn.StateName='W';
    dyn.OutputName={'W','w'};
end


%%Stiff drivetrain dynamics
function dyn=getDrivetrainDynSs(drt)
    %  Rotor inertia at low speed side 
    Jrot = drt.RotInertia;
    % Generator inertia at low speed side
    Jgen_hss = drt.GenInertia;
    Jgen_lss = Jgen_hss*drt.GearRatio^2;
    % Total inertia includes blade inertia and hub inertia
    Jtot = Jrot + Jgen_lss;
    
    % LLS reference system
    % u: [Mrot ; Mgen ; vWy]
    % x1: OmegaLSS
    % y: [OmegaLSS; omegaHSS]
    F = 0; 
    G = (1/Jtot)*[1  -1  0];
    H = [1; drt.GearRatio*30/pi];
    J = [0 0 -1; 0 0 -drt.GearRatio*30/pi];
    dyn = ss(F,G,H,J);
   
    dyn.InputName={'Mrot','Mgen','vWy'};
    dyn.StateName='W';
    dyn.OutputName={'W','w'};
end


%%Stiff drivetrain dynamics
function dyn=getDrivetrainDynSsDmp(drt)
    %  Rotor inertia at low speed side 
    Jrot = drt.RotInertia;
    % Generator inertia at low speed side
    Jgen_hss = drt.GenInertia;
    Jgen_lss = Jgen_hss*drt.GearRatio^2;
    % Total inertia includes blade inertia and hub inertia
    Jtot = Jrot + Jgen_lss;
    
    % LLS reference system
    % u: [Mrot ; Mgen]
    % x1: OmegaLSS  
    % y: [OmegaLSS; omegaHSS]
    F = 0; 
    G = (1/Jtot)*[1  -1  -1  0];
    H = [1; drt.GearRatio*30/pi];
    J = [0 0 0 -1; 0 0 0 -drt.GearRatio*30/pi]; 
    dyn = ss(F,G,H,J);
    
    dyn.InputName={'Mrot','Mgen','dmpMgen','vWy'};
    dyn.StateName='W';
    dyn.OutputName={'W','w'};
end


%%Flexible drivetrain dynamics, 2 mass, spring-damper
function dyn=getDrivetrainDynFree2(drt)    
    % u: [Mrot ; Mgen]
    % y: [OmegaLSS; wHSS]    
    dyn = wtLin.driveTrainFree2(drt);
end


%Aerodynamics including induction lag
function dyn=getAeroDynPLC(aero)
    
    %Note below is obsolete, only induction lag on dMdw
    %Taylor lin
    %Mstat=dMrot.dth*th+dMrot.dv*v+dMrot.dw*w
    %Induction lag
    %dMrot.dt=-1/tauIL*Mrot+1/tauIL*Mstat 
    
    %Aerodynamics
    %u: [th;v;w_LSS]
    %x: Mrot
    %y: Mrot
    F = -1/aero.tauIL; 
    G = 1/aero.tauIL*[0 0 aero.dM.dw];
    H = 1;
    J = [aero.dM.dth, aero.dM.dv 0]; 
    dyn = ss(F,G,H,J);
    
    dyn.InputName={'th','v','W'};
    dyn.StateName='Mrot';
    dyn.OutputName='Mrot';
    
end

%Aerodynamics including induction lag
function dyn=getAeroDynFLC(aero)
    
    %Note below is obsolete, only induction lag on dMdw
    
    %Aerodynamics
    %u: [th;v;w_LSS]
    %x: Mrot
    %y: Mrot
    F = 0; 
    G = [0 0 0];
    H = 1;
    J = [aero.dM.dth, aero.dM.dv aero.dM.dw];
    dyn = ss(F,G,H,J);
    
    dyn.InputName={'th','v','W'};
    dyn.StateName='Mrot';
    dyn.OutputName='Mrot';
    
end

%Generator model
function dyn=getGeneratorDyn(gen)

    %Taylor linearisation
    %Mgen=dMgen.dPconv*Pconv+dMgen.dw*w
    
    %Generator
    %u: [Pconv;W] 
    %x: Mgen
    %y: Mgen
    F = 0; 
    G = [0 0];
    H = 0;
    J = [gen.dM.dP, gen.dM.dw]; 
    dyn = ss(F,G,H,J);
    
    dyn.InputName={'Pconv','W'};
    dyn.StateName='Mgen';
    dyn.OutputName='Mgen';

end



%Simplified Converter dynamics
function dyn=getConverterDyn(cnv)

    %1st order equivalent
    %dPconv.dt=-1/tauConv*Pconv+1/tauConv*Pref 
    
    %Converter
    %u: Pref
    %x: Pconv
    %y: Pconv
    F = -1/cnv.tau; 
    G = 1/cnv.tau;
    H = 1;
    J = 0; 
    dyn = ss(F,G,H,J);

    dyn.InputName='Pref';
    dyn.StateName='Pconv';
    dyn.OutputName='Pconv';
end


%Simplified Converter dynamics - Gain=1
function dyn=getConverterDynUnity
    %Converter dynamics
    %u: Pref
    %y: Pconv
    dyn = tf(1,1);
    dyn.InputName='Pref';
    dyn.OutputName='Pconv';
end


%Simplified Converter dynamics with DTD
function dyn=getConverterDtdDyn(cnv)
    
    %Converter
    %u: Pref
    %x: Pconv
    %y: Pconv
    F = -1/cnv.tau; 
    G = [1/cnv.tau  1/cnv.tau];
    H = 1;
    J = [0  0]; 
    dyn = ss(F,G,H,J);  

    dyn.InputName={'Pref','Pdtd'};
    dyn.StateName='Pconv';
    dyn.OutputName='Pconv';
end


%Simplified Converter dynamics with DTD
function dyn=getConverterDtdDynUnity    
    %Converter
    %u: Pref, Pdtd
    %x: Pconv
    %y: Pconv
    F = 0; 
    G = [0 0];
    H = 0;
    J = [1 1]; 
    dyn = ss(F,G,H,J);
    dyn.InputName={'Pref','Pdtd'};
    dyn.StateName='Pconv';
    dyn.OutputName='Pconv';
end


% DTD - Drive Train Damping
function dyn=getDTD(dtd) 
    % u: wHSS
    % y: Pdtd
    dyn = wtLin.tfDTD(dtd);
end


%Simplified Pitch dynamics
function dyn=getPitchDyn(pit)   
    %1st order equivalent
    %dTh.dt=-1/tauTh*Th+1/tauTh*Thref 
    %
    %Pitch model
    F = -1/pit.tau; 
    G = (1/pit.tau)*[1 1];
    H = 1;
    J = [0 0]; 
    dyn = ss(F,G,H,J);
    dyn.InputName={'thRef','thFatd'};
    dyn.StateName='th';
    dyn.OutputName='th';
end


%Simplified Pitch dynamics - Gain=1 version
function dyn=getPitchDynUnity    
    %Pitch model
    F = 0; 
    G = [0 0];
    H = 0;
    J = [1 1]; 
    dyn = ss(F,G,H,J);
    dyn.InputName={'thRef','thFatd'};
    dyn.StateName='th';
    dyn.OutputName='th';
end


%Aerodynamics - Thrust
function dyn=getAeroDynThrust(aero)
        
    %Aerodynamics
    %u: [th;v;w_LSS]
    %x: Trot
    %y: Trot
    F = 0; 
    G = [0 0 0];
    H = 1;
    J = [aero.dF.dth, aero.dF.dv aero.dF.dw];
    dyn = ss(F,G,H,J);
    
    dyn.InputName={'th','v','W'};
    dyn.StateName='Trot';
    dyn.OutputName='Trot';
    
end


% 1st mode f-a tower model
function dyn=getTowerSpringMassFa(tow)

    % Tower dynamics
    % mass-spring-damper system

    frqHz1 = tow.frqHz1;
    m = tow.mass;
    
    %%%% omega^2 = k/m 
    ky = ((frqHz1*2*pi)^2)*m;

    % zeta * 2 * sqrt(k*m) = b  
    zeta = 0.02;
    by = zeta * 2 * sqrt(m*ky);

    % Coordinate sys
    % Fixed to tower base, right-hand coor sys
    % y-axis pointing down-wind
    % z-axis pointing up-wards
    
    %Tower model
    %u: Thrust
    %x1: tower top y-position
    %x2: tower top y-velocity
    %y: x1 x2
    F = [0 1; -ky/m -by/m];
    G = [0; 1/m];
    H = [1 0; 0 1];    
    J = [0; 0];
    % Including acc in output
    H = [H; F(2,:)];
    J = [J; G(2,:)]; 
    dyn = ss(F,G,H,J);

    dyn.InputName = {'Trot'};
    dyn.StateName = {'py','vy'};
    dyn.OutputName = {'py','vy','ay'};
end


% Rotor wind, i.e. tower movement compensation
% v = vfree - vy
function dyn=getRotorWind
    % Rotor wind speed
    % u: [vfree;vy]
    % x: v
    % y: v
    F = 0; 
    G = [0 0];
    H = 0;
    J = [1 -1]; 
    dyn = ss(F,G,H,J);
    
    dyn.InputName={'vfree','vy'};
    dyn.StateName='v';
    dyn.OutputName='v';  
end


% 1st mode s-s tower model
% Notice, could be extended with 2nd mode
function dyn=getTowerSpringMassSs(tow) 

    % Tower dynamics
    % mass-spring-damper system
    
    frqHz1 = tow.frqHz1;
    m = tow.mass;
    hh = tow.hubHeight;
   
    % omega^2 = k/m 
    kx = ((frqHz1*2*pi)^2)*m;

    % zeta * 2 * sqrt(k*m) = b  
    zeta = 0.02;
    bx = zeta * 2 * sqrt(m*kx);

    % Coordinate sys
    % Fixed to tower base, right-hand coor sys
    % x-axis pointing sideways
    % z-axis pointing up-wards
    
    % modify hh to accont for 2nd mode deflection
    hheff = hh * 0.45; % should be calculated instead
    
    %Tower model
    %u: Driving moments
    %x1: tower sideways x-position
    %x2: tower sideways x-velocity
    %y: angle, angular velocity
    F = [0 1; -kx/m -bx/m];
    G = [0 0; 1/(m*hheff) -1/(m*hheff)]; 
    H = [1/hheff 0; 0 1/hheff];    
    J = [0 0; 0 0];
    dyn = ss(F,G,H,J);

    dyn.InputName = {'Mrot','Mgen'};
    dyn.StateName = {'px','vx'};
    dyn.OutputName = {'pWy','vWy'}; % rad, rad/s
end


% Controller rotor damping by power
function dyn=getPowRotDampFLC(rotDmp)
    KRotDamp = rotDmp.KRotDamp;
    
    F = 0;
    G = 0;
    H = 0;    
    J = KRotDamp;
    dyn = ss(F,G,H,J);

    dyn.InputName = 'W';
    dyn.OutputName = 'dmpMgen';
end


% Kalman filter based on SDOF f-a tower model
function dyn=getKalmanTowerFa(tow)

    %Ts=0.1; % for discrete version

    %%%%%%%%%%%%%% Tower dynamics, mass-spring-damper system
    frqHz1 = tow.frqHz1;
    m = tow.mass;
    ky = ((frqHz1*2*pi)^2)*m; % omega^2 = k/m   
    zeta = 0.02;
    by = zeta * 2 * sqrt(m*ky); % zeta * 2 * sqrt(k*m) = b
    % --- Coordinate sys ---
    % Fixed to tower base, right-hand coor sys
    % y-axis pointing down-wind
    % z-axis pointing up-wards
    % --- Tower model ---
    % u: Thrust
    % x1: tower top y-position
    % x2: tower top y-velocity
    % y: x1 x2
    F = [0 1; -ky/m -by/m];
    G = [0; 1/m];
    H = [1 0; 0 1];    
    J = [0; 0];
    twr = ss(F,G,H,J);
    twr.InputName = {'Trot'};
    twr.StateName = {'py','vy'};
    twr.OutputName = {'py','vy'};
    
    %%%%%%%%%%%%%% Kalman Filter
    % Model for KMF
    % Gets the state transition row, from speed -> acceleration
    nStates   = length(twr.StateName);
    nOutput   = length(twr.OutputName);
    spd2accIdx    = strmatch('vy', twr.StateName);
    % Process noise, each state has independent noise acting on it
    G        = eye(nStates);
    % Augments inputs with stochastic noise
    A        = twr.A;
    B        = [twr.B G];                       % Noise input 
    C        = [twr.C; twr.A(spd2accIdx,:)];    % Measurement of acceleration; 
    D        = [twr.D; twr.B(spd2accIdx,:)];    % Measurement of acceleration
    nOutput  = nOutput + 1;                     % Number of outputs is now updated
    H        = zeros(nOutput, nStates);         % Informs that no state noise affects the measurements
    D        = [D H];                           % Appends noise matrix to observation
    % Tower fore-aft SDOF model - Continuous time
    twrAcc = ss(A, B, C, D);
    twrAcc.InputName  = {'Trot', 'TwrPosNoise', 'TwrVelNoise'};
    twrAcc.StateName  = {'TwrPos' ; 'TwrSpd'};
    twrAcc.OutputName = {'TwrPos' ; 'TwrSpd'; 'TwrAcc'};
    %twrAccD = c2d(twrAcc, Ts); % Discrete version

    % Kalman filter observer design
    Qn      = diag([1,1]);
    Rn      = 1;
    Nn      = [];
    sensors = 3;
    known   = 1; % Known input is Trot, thrust force estimate
    [kalmf, K, ~, M, Z] = kalman(twrAcc, Qn, Rn, Nn, sensors, known, 'delayed');
    %[kalmfd, K, ~, M, Z] = kalman(twrAccD, Qn, Rn, Nn, sensors, known, 'delayed');    
    dyn = kalmf;
    dyn.InputName  = {'Trot', 'ay'};
    dyn.OutputName = {'ayEst','pyEst','vyEst'}; % check if order is correct
    %kalmanPole = eig(kalmf.A);
    %towerPole  = eig(twrAcc.A);
       
end






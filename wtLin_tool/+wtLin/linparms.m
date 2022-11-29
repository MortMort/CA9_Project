classdef linparms < wtLin.mapAbleStruct
   
    methods (Static)
      function lp=calcParms(gp,op)
        lp=wtLin.linparms();
        lp.s.stat=calcOP(gp,op);
        [lp.s.mp,lp.s.info]=getLinParams(gp,op,lp.s.stat);
      end
    end
    
end


%%
function [mp,info]=getLinParams(gp,op,stat)

    o=op.s;
    g=gp.s;

    
    %% Tower
    mp.twr.frqHz1 = g.twr.frqHz1;
    mp.twr.mass = g.twr.mass;
    mp.twr.hubHeight = g.twr.hubHeight;

    
    %% Calculation of gain scheduled PI parameters of PLC 
    if (stat.genSpd < g.ctr.plc.GenSpd_Min)
        mp.ctr.plc.Kp = g.ctr.plc.KP_Min;
    elseif ( (stat.genSpd >= g.ctr.plc.GenSpd_Min) && ( stat.genSpd <= g.ctr.plc.GenSpd_Nom) )
        mp.ctr.plc.Kp = (( g.ctr.plc.KP_Nom - g.ctr.plc.KP_Min ) / ( g.ctr.plc.GenSpd_Nom - g.ctr.plc.GenSpd_Min)) * (stat.genSpd - g.ctr.plc.GenSpd_Min) + g.ctr.plc.KP_Min;
    else %  ( Ref > SpdNom )
        mp.ctr.plc.Kp = fcp.plc.KP_Nom;
    end
    
    %%Correct sign for negative feedback
    mp.ctr.plc.Kp = -1*mp.ctr.plc.Kp;
    mp.ctr.plc.Ti = g.ctr.plc.Ti;
    
    
    %% Calculate equivalent pitch controller parameters
    mp.pit.tau=calcPitchTau(g.pit,g.ctr.pipc);
    
    %% Calculate equivalent converer parameters
    mp.cnv.tau=0.5;
   
    %% DTD
    mp.dtd = g.dtd;
    mp.dtd.genSpd = stat.genSpd;
    mp.dtd.gridFreq = g.gen.gridFreq;
    
    %% Drivetrain
    mp.drt.RotInertia=g.rot.inertia;
    mp.drt.GenInertia=g.gen.inertia;
    mp.drt.GearRatio=g.drt.gearRatio;
    mp.drt.eigfrequency = g.drt.eigfreq;
    mp.drt.torsstiffness = g.drt.torsStiffness;
    mp.drt.torsdamping = g.drt.torsDampingLogDecr;
    mp.drt.useEigFreq = g.drt.useEigFreq;
    
    
    %% Calculate generator
    %Loss in kW
    %dPm.dP in kW/kW = W/W
    %dPm.dW in kW/RPM_HSS
    %kW/RPM_HSS->W/(rad/s)_LSS
    
    
    [Ploss,dPm,etaA,etaE,etaM]=wtLin.getLosses(stat.power/1000,stat.genSpd,g.gen);
    
    %Convert losses to W
    Ploss=Ploss*1000;
    
    info.gen.Ploss=Ploss;
    info.gen.etaA=etaA;
    info.gen.etaE=etaE;
    info.gen.etaM=etaM;
    
    %Generator speed at low speed side in SI units: wl=w*2*pi/60/N
    wl=stat.genSpd*2*pi/60/g.drt.gearRatio;
    
    %Generator torque: Mg=(P+Ploss)/w=Pm/w
    %dMg.dP=dPm.dP/w
    mp.gen.dM.dP=dPm.dP/wl; %Torque variation with power set point
    
    
    %dMg.dw=(dPm.dw*w-(P+Ploss))/w^2
    %      =Dric+Dpower
    %      =dPm.dw/w-(P+Ploss)/w^2
    cFact=1000*2*pi/60*g.drt.gearRatio;
    Dfric=dPm.dw*cFact/wl; %Damping due to losses changing
    Dpower=-(stat.power+Ploss)/wl^2; %(negative) Damping due to set point 
    mp.gen.dM.dw=Dfric+Dpower; %Total damping
    
    info.gen.Dfric=Dfric;
    info.gen.Dpower=Dpower;
    

    %% calculate aerodynamic derivatives 
    dd=wtLin.aerodiff(stat.lambda,stat.pitch,g.aero);
    
    info.aero=dd;
    
    Arot=g.rot.radius^2*pi;
    rho=o.env.airDensity;
    radius=g.rot.radius;
    
    aero.dM.dv = rho/2*Arot * radius * o.env.wind * (2*dd.cM - stat.lambda*dd.dcM.dl);
    aero.dM.dw = rho/2*Arot * radius^2 * o.env.wind * dd.dcM.dl;
    aero.dM.dth = rho/2*Arot * radius * o.env.wind^2 * dd.dcM.dth;
    aero.dF.dv = rho/2*Arot * o.env.wind * (2*dd.cT - stat.lambda*dd.dcT.dl);
    aero.dF.dw = rho/2*Arot * radius * o.env.wind * dd.dcT.dl;
    aero.dF.dth = rho/2*Arot * o.env.wind^2 * dd.dcT.dth;
    
    %%Calculate induction lag
    %aero.tauIL=10;
    aero.tauIL = g.aero.tauIL;
    
    mp.aero=aero;


    %% FLC
    [pitGS,pitLinGS,pitSensGS] = wtLin.ThetaGS(g,o,stat,stat.pitch);
    windGS = wtLin.WindGS(stat.pitch,g.ctr.flc);
    GS = pitGS * windGS;
    
    info.ctr.flc.pitGS = pitGS;
    info.ctr.flc.pitLinGS = pitLinGS;
    info.ctr.flc.pitSensGS = pitSensGS;
    info.ctr.flc.windGS = windGS;
    info.ctr.flc.GS = GS;
    
    Hss2Lss = 1/g.drt.gearRatio; % input to FLC is GenSpd
    mp.ctr.flc.Kp = Hss2Lss * g.ctr.flc.K_PI*GS;
    mp.ctr.flc.Ti = g.ctr.flc.tau_i;  
    
    mp.ctr.flc.KRotDamp = g.ctr.flc.KRotDamp; % test feature

    
    %% Drive train filters values are linear
    mp.ctr.sp=g.ctr.sp;

    
    %% FATD
    [KposGS,KvelGS] = wtLin.GainSchFATD(g.ctr.fatd,o.env.wind,g.twr.frqHz1);
    info.ctr.fatd.KposGS = KposGS;
    info.ctr.fatd.KvelGS = KvelGS;
    
    mp.ctr.fatd.Kpos = g.ctr.fatd.KpTwrPos * KposGS;  
    mp.ctr.fatd.Kvel = g.ctr.fatd.KpTwrSpd * KvelGS;    
    
    % Rotor damping in FLC
    mp.ctr.flc.KRotDamp = g.ctr.flc.KRotDamp;


    
    
end


%%
function stat=calcOP(gp,op)
    %%Calculates the operating point based on the op info
    %%Includes OTC and static TL
    %%Todo VTL 

    import wtLin.*;
    o=op.s;
    g=gp.s;
    
    %%Check for HWO
    %Currently not supported
    if false %(isfield(g.ctr,'hwo') && o.ctrl.HWOenabled && o.env.wind>=g.ctr.hwo.wind(1))
%          [~,hwoMode]=min(abs(pars.wind-fcp.hwo.wind));
%          maxSpeed=fcp.hwo.genSpd(hwoMode);
%          maxPower=fcp.hwo.power(hwoMode)*1000;
    else
        %Nominal speed 
        maxSpeed=g.ctr.sc.NomSpd;
        flPower=g.ctr.NomPow*1e3;
    end

    %Check for custom set points 
    powSet=false;
    pitchSet=false;    
    if(isfield(o,'setPoint'))
        
        if (isfield(o.setPoint,'genRPM'))
            stat.genSpd=o.setPoint.genRPM;
        else
            %Calculate generator speed reference based on optimal lambda
            gspd=o.env.wind*g.ctr.sc.LambdaOpt/g.rot.radius*g.drt.gearRatio*30/pi;

            %Limit generator speed reference between min and max speed
            stat.genSpd=max(min(gspd,maxSpeed),g.ctr.sc.MinSpd);
        end
        
        if(isfield(o.setPoint,'power'))
            stat.power=o.setPoint.power;
            powSet=true;
        end
        if(isfield(o.setPoint,'pitch'))
            stat.pitch=o.setPoint.pitch;
            pitchSet=true;
        end
        if (powSet && pitchSet)
            warning('Defining power and pitch set points might result in a bad model, please pick 1 or let the script calculate the set point');
            if (stat.power>=flPower)
                stat.ctr.FullLoad=true;
            else
                stat.ctr.FullLoad=false;
            end
            return %No more to be done
        end
    else
        %Calculate generator speed reference based on optimal lambda
        gspd=o.env.wind*g.ctr.sc.LambdaOpt/g.rot.radius*g.drt.gearRatio*30/pi;

        %Limit generator speed reference between min and max speed
        stat.genSpd=max(min(gspd,maxSpeed),g.ctr.sc.MinSpd);
    end
    
    
    
    %Calculate lambda
    stat.lambda=stat.genSpd/g.drt.gearRatio*pi/30*g.rot.radius/o.env.wind;
    
    %Calculate OTC opti-wind pitch angle
    stat.ctr.optiPitch=interp1ep(g.ctr.otc.tab.lambda,g.ctr.otc.tab.pitch,stat.lambda);

    %At each wind speed the following power is available...
    stat.Pwind = 0.5*o.env.airDensity*pi*g.rot.radius^2*o.env.wind^3;
    
    %TL
    [stat.ctr.tl.offset,stat.ctr.tl.slope]=calcSlopeOffset(g.ctr.tl,stat,o);
        
    %Fixed pitch angle set point
    if(pitchSet)
        %Find grid power
        [stat.power,stat.Prot,stat.Cp]=getGridPower(g,o,stat,stat.pitch);
        %Find TL pitch angle
        stat.ctr.tl.minPitch=TLPitch(g,stat,stat.power,stat.pitch);        
        %%Assuming partial load when pitch angle is chosen
        stat.FullLoad=false;
    elseif (powSet) %Fixed power set point
        %Calculate FL pitch angle given the power setting
       [stat.pitch,stat.Prot,stat.Cp]=calcFLPitch(g,stat);
       %Assuming full load when setting power  
       stat.ctr.FullLoad=true;       
    else %%Find power and pitch setpoints automatically
        
        %Find min pitch angle given wind speed and gen speed 
        minPitch=fzero( @(x) findTLminPitch(g,o,stat,x),stat.ctr.optiPitch);
       
        %Find grid power for wind, gen speed and pitch set point
        [power,Prot,Cp]=getGridPower(g,o,stat,minPitch);
        
        %Limit grid power to nominal power
        if power>(flPower)
            stat.power=flPower;
            [stat.pitch,stat.Prot,stat.Cp]=calcFLPitch(g,stat);
            stat.ctr.FullLoad=true;
            stat.Cp=Cp;
            stat.ctr.tl.minPitch=TLPitch(g,o,stat,power,stat.pitch);
        else
            stat.power=power;
            stat.Prot=Prot;
            stat.Cp=Cp;
            stat.pitch=minPitch;
            stat.ctr.FullLoad=false;
            stat.ctr.tl.minPitch=TLPitch(g,o,stat,power,stat.pitch);
        end          
            
    end

    %Check if full or partial load is forced  
    %easier than isfield when it is a subfield with a parent field that
    %might not exist which is to be checked.
    m=op.asMap;
    if(m.isKey('ctrl.FL')) 
        stat.ctr.FullLoad=o.ctrl.FL;
    end


     if((stat.pitch+10*eps)<stat.ctr.optiPitch)
         warning('The chosen operating point is not possible! below OptiPitch curve');    
     end

     if((stat.pitch+10*eps)<stat.ctr.tl.minPitch)
         diff=stat.pitch-stat.ctr.tl.minPitch
         warning('The chosen operating point is not possible! below thurst limiter pitch setting');    
     end

    %Limit grid power to nominal power
    if stat.power>(flPower)
        warning('Power higher than nominal power')
    end

end

   

%%
%function for finding difference between rotor power and grid power +
%losses
%FIXME
function Pdiff=getPowBalance(g,stat,power,Prot) 
 [Ploss,~,~,~,~]=wtLin.getLosses(power/1000,stat.genSpd,g.gen);
 Pdiff=Prot-(Ploss*1000+power);
end


%%
%TL pitch angle, only supports fixed TL
function dPitch=findTLminPitch(g,o,stat,pitch)
        %stat.optiPitch
        [power,~,~]=getGridPower(g,o,stat,pitch);
        %TL pitch angle
        Pitch_TL=TLPitch(g,o,stat,power,pitch);     
        %Pitch difference
        dPitch=max(Pitch_TL,stat.ctr.optiPitch)-pitch;
        %dPitch=abs(Pitch_TL-pitch);
end


%%
function Pitch_TL=TLPitch(g,o,stat,power,pitch)
    %
    [pitGS,~,~] = wtLin.ThetaGS(g,o,stat,pitch);
    Pitch_TL=stat.ctr.tl.offset+stat.ctr.tl.slope*(power/g.ctr.NomPow/1000-1)*pitGS;  
end


%%
function [Pgrid,Prot,Cp]=getGridPower(g,o,stat,pitch)
    %Find CP value
    Cp=wtLin.interp2ep(g.aero.lambda,...    
                        g.aero.theta,... 
                        g.aero.cp,... 
                        stat.lambda,...
                        pitch);
    %Calculate rotor power as used by TL (without losses)
    Prot = 0.5*o.env.airDensity*pi*g.rot.radius^2*o.env.wind^3*Cp;
    %Find grid power by iteration
    Pgrid=fzero(@(x) getPowBalance(g,stat,x,Prot),Prot*0.85);
end


%%
function [pitch,Prot,Cp]=calcFLPitch(g,stat)
    %Calculate losses for rotor power and CP value
    [Ploss,~,~,~,~]=wtLin.getLosses(stat.power/1000,stat.genSpd,g.gen);
    Ploss=Ploss*1000;

    Prot = stat.power+Ploss;
    %The turbine is operating at the following aerodynamic Cp
    Cp =  Prot/stat.Pwind;

    %Check CP values
    CP_max=max(max(g.aero.cp));
    if(CP_max<Cp)
        warning('The chosen operating point is not possible! CPmax exceedance');    
    end

    pitch = wtLin.inv_Cp(...
                    g.aero.theta,...    
                    g.aero.lambda,... 
                    g.aero.cp,... 
                    stat.lambda,...    
                    Cp);     
end


%%
function [offset,slope]=calcSlopeOffset(tl,stat,o)
    import wtLin.*;
    if(isfield(o,'ctrl') && (isfield(o.ctrl,'EnableTL') && ~o.ctrl.EnableTL))
        %Fake disable of TL
        offset=-10;
        slope=0;
    else
        %VTL
        if (isfield(o,'ctrl') && isfield(tl,'vtl') && tl.vtl.enabled && ((isfield(o.ctrl,'EnableVTL') && ~o.ctrl.EnableVTL)))
            if(isfield(o.ctrl,'thrustLevel'))
                tLevel=o.ctrl.thrustLevel;
            else
                tLevel=max(tl.vtl.thrust); %Choose the highest thrust limiter setting 
            end
            %Find the two nearest thrust curves
            minIdx=find(tl.vtl.thrust<tLevel,'last');
            maxIdx=find(tl.vtl.thrust>tLevel,'first');
            
            %Find offset for the two thrust curves
            offset1=interp1ep(tl.vtl.offset.genSpd(:,minIdx),tl.vtl.offset.pitch(:,minIdx),stat.genSpd);
            offset2=interp1ep(tl.vtl.offset.genSpd(:,maxIdx),tl.vtl.offset.pitch(:,maxIdx),stat.genSpd);
            %Interpolate between the two offset values
            offset=interp1ep([tl.vtl.thrust(minIdx) tl.vtl.thrust(maxIdx)],[offset1 offset2],thrust);

            %Find slope for the two thrust curves
            slope1=interp1ep(tl.vtl.slope.genSpd(:,minIdx),tl.vtl.slope.pitchPPu(:,minIdx),stat.genSpd);
            slope2=interp1ep(tl.vtl.slope.genSpd(:,maxIdx),tl.vtl.slope.pitchPPu(:,maxIdx),stat.genSpd);
            %Interpolate between the two offset values
            slope=interp1ep([tl.vtl.thrust(minIdx) tl.vtl.thrust(maxIdx)],[slope1 slope2],thrust);
           
            
        else
            %%Static thrust limiter
            offset=interp1ep(tl.offset.genSpd,tl.offset.pitch,stat.genSpd);
            
            %not really pitchPkW, rather pitch per Pu
            slope=interp1ep(tl.slope.genSpd,tl.slope.pitchPkW,stat.genSpd);
        end
    end
end


%%
%Calculate pitch system equivalent time constant using system reduction
function tau=calcPitchTau(pit,pipc)
%% The pitch system 
Pade2use        = 3;


%Pitch speed as a funtion of error
%interp1 ep does not support vectors properly
dThetadErr = interp1(pit.propVol,pit.pitSpd,pipc.cVol);


%Calculate the speed for some error...Using average of -1 to 1 deg?
pErr=-1:0.1:1;
pitSpd=interp1(pipc.pitErr,dThetadErr,pErr);
%Find the gradient and take the mean to calculate the gain used in this
%model
dThetadErr_0=mean(gradient(pitSpd,pErr));

%Hydraulic dynamics and pitch rate to pitch integration
Hyd_dyn         = tf(1,[pit.timeconst 1 0]); % [deg/V]

%Now a closed loop pitch control system is generated for tje time delay
%(the time delay model is a Padé approximation with order 'Pade2Use')
%Closed loop Hcl = forward/(1+openloop)
[NumTd,DenTd]    = pade(pit.delay,Pade2use);
Pitch_cl         = feedback(tf(NumTd,DenTd)*dThetadErr_0*Hyd_dyn,1); 

[rsys] = balred(Pitch_cl,1);  % Compute balanced realization

%Assume no direct feedthrough and DC gain of one
tau=1/rsys.den{1}(2);
end

function returnPeriodCalc(config,outfolder,turbname,k,Vave)
% Calculates the 50-year EV event return period using two methods:
% Z-Factor Method: Based on the probability of an EV event exceeding the
% peak-to-peak bending moment threshold.
% W-Factor Method: Based on the weighted probability of an EV event (scaled
% by the peak load) at the return period wind speed.

includeWfacCalc = false;

%% USER INPUT
suffix={'Locked','Idle'};
ILString={'lock','idle'};

% Vave = 0.2*V50; %(I-50; II-42.5; III-37.5)
% k = 2;
Ttarget=50; % Target return perdiod of 50 years

%Frequency/time period of independent 10-min periods in Hz & seconds respectively
nu = 7.3e-4;
T = 1/nu;
C =  Vave/(gamma(1+1/k));  % if (k == 2) -> C = 2*Vave/(sqrt(pi));

load([outfolder '/' turbname '_' config.case '_' 'ZFac.mat'])
N=length(azim);
M=length(wdir);
K=length(mis);

%% ZFAC CALCULATION
if any(Zfac) == 1
    Pw = zeros(length(wsps),1);
    Pr = Pw;
    Pev = Pw;
    Tr.ZFAC = Pw;

    for i = 1:length(wsps)
        if Zfac(i)>0
            Pw(i) = exp(-(wsps(i)/C)^k); % Weibull Probability of windspeed exceeding wsps
            Pev(i) = Zfac(i)*Pw(i); % Probability of EV
            Tr.ZFAC(i) = (T/Pev(i))/(365*24*60*60); % Return Period
        else
            Tr.ZFAC(i)=0;
        end
    end

    PevTarget = T/(Ttarget*(365*24*60*60));

    interpInd=[find(Zfac~=0)-1:length(wsps)];
    interpInd=interpInd(interpInd~=0);
%     ZfacTarget=interp1(wsps(interpInd),Zfac(interpInd),interp1(Tr.ZFAC(interpInd),wsps(interpInd),Ttarget,'pchip','extrap'),'pchip','extrap');
    ZfacTarget=interp1(wsps(interpInd),Zfac(interpInd),interp1(Tr.ZFAC(interpInd),wsps(interpInd),Ttarget,'linear','extrap'),'linear','extrap');
    
    if ZfacTarget>PevTarget
    PwTarget = PevTarget/ZfacTarget;
    else 
        PwTarget=PevTarget;
    end
    VTarget.ZFAC = C*nthroot((-log(PwTarget)),k);


    %% Weighted Loads Calculation
    Pw = zeros(length(wsps),1);
    Pr = Pw;
    Pev = Pw;
    Tr.WFAC = Pw;

    peakLoads=zeros(length(wsps),1);
    for i=1:length(wsps)
        peakLoads(i)=max(max(max(Loads(:,:,:,i))));%peakLoads(i)=max(max(Loads(:,:,i)));
    end
    WLoad=interp1(wsps,peakLoads,VTarget.ZFAC,'pchip');
    NLoads=zeros(3*N,M,K,length(wsps));
    Wfac=zeros(length(wsps),1);
    for i=1:length(wsps)
        NLoads(:,:,:,i) = Loads(:,:,:,i)./WLoad;%NLoads(:,:,i) = Loads(:,:,i)./WLoad;
        Wfac(i) = sum(sum(sum(NLoads(:,:,:,i))))/(M*N*K*3);%sum(sum(NLoads(:,:,i)))/(M*N*3);
    end

    for i = 1:length(wsps)
        if Wfac(i)>0
            Pw(i) = exp(-(wsps(i)/C)^k); % Weibull Probability of windspeed exceeding wsps
            Pev(i) = Wfac(i)*Pw(i); % Probability of EV
            Tr.WFAC(i) = (T/Pev(i))/(365*24*60*60); % Return Period
        else
            Tr.WFAC(i)=0;
        end
    end

    PevTarget = T/(Ttarget*(365*24*60*60));
    WfacTarget=interp1(wsps,Wfac,interp1(Tr.WFAC,wsps,Ttarget,'pchip'),'pchip');
    if WfacTarget>PevTarget
        PwTarget = PevTarget/WfacTarget;
    else 
        PwTarget = PevTarget;
    end
    VTarget.WFAC = C*nthroot((-log(PwTarget)),k);
else    
    Zfac(1:length(wsps)) = 0; Wfac(1:length(wsps)) = 0; 
    Tr.ZFAC(1:length(wsps)) = 0; Tr.WFAC(1:length(wsps)) = 0;
    VTarget.ZFAC = 0; ZfacTarget = 0;
    VTarget.WFAC = 0; WfacTarget = 0;
end

%% Write Outputs
if includeWfacCalc
    fidZ=fopen([outfolder '/' turbname '_' config.case '_' 'ZFac.txt'],'w');
    fidW=fopen([outfolder '/' turbname '_' config.case '_' 'WFac.txt'],'w');

    fprintf(fidZ,'Wind Speed (m/s)\tZFac\tReturn Period (yrs)\n');
    fprintf(fidW,'Wind Speed (m/s)\tWFac\tReturn Period (yrs)\n');
    for i=1:length(wsps)
        fprintf(fidZ,'%.1f\t%.4f\t%.3f\n',wsps(i),Zfac(i),Tr.ZFAC(i));
        fprintf(fidW,'%.1f\t%.4f\t%.3f\n',wsps(i),Wfac(i),Tr.WFAC(i));
    end
    fprintf(fidZ,'%.1f\t%.4f\t%.3f\n',VTarget.ZFAC,ZfacTarget,50);
    fprintf(fidW,'%.1f\t%.4f\t%.3f\n',VTarget.WFAC,WfacTarget,50);
    fclose(fidZ);
    fclose(fidW);
else
    fidZ=fopen([outfolder '/' turbname '_' config.case '_' 'ZFac.txt'],'w');

    fprintf(fidZ,'Wind Speed (m/s)\tZFac\tReturn Period (yrs)\n');
    for i=1:length(wsps)
        fprintf(fidZ,'%.1f\t%.4f\t%.3f\n',wsps(i),Zfac(i),Tr.ZFAC(i));
    end
    fprintf(fidZ,'%.1f\t%.4f\t%.3f\n',VTarget.ZFAC,ZfacTarget,50);
    fclose(fidZ);
end

save([outfolder '/' turbname '_' config.case '_ReturnPeriod.mat'],'wsps','Zfac','Wfac','Tr','VTarget','ZfacTarget','WfacTarget')
    

function dyn = tfDTD(dtdParam)


if dtdParam.enable == 1
%% Pre filter
wHpPre = 2*pi*dtdParam.fHpPre;
dynHpPre = tf([1/wHpPre 0],[1/wHpPre 1]);

%% DTD filter
if strcmp(dtdParam.dtdType,'Hp_HpLp')
    %
    wHpDtd = 2*pi*dtdParam.fHpDtd;
    dynHpDtd = tf([1/wHpDtd 0],[1/wHpDtd 1]);
    %
    wLpDtd = 2*pi*dtdParam.fLpDtd;
    dynLpDtd = tf(1,[1/wLpDtd 1]);
    %
    KDtd = dtdParam.K_LPF_HPF_DTD;
    dynDtd = KDtd*dynHpDtd*dynLpDtd;
    %
elseif strcmp(dtdParam.dtdType,'Hp_Reson')
    %
    fDT = dtdParam.fDT;
    GDT_DTD_dB = dtdParam.GDT_DTD_dB;
    eta_f = 0.2; % fixed in all configurations
    eta_fBW = 0.5; % fixed in all configurations
    eta_BW = dtdParam.eta_BW; 
    [Ki,wcu,~]= wtLin.HDTD_param(fDT,GDT_DTD_dB,eta_f,eta_fBW,eta_BW);
    wdt = 2*pi*dtdParam.fDT;
    dynDtd = Ki*tf([2*wcu  0],[1  2*wcu  wdt^2]);
    %
else
    %
    dynDtd = tf(1,1);
    disp('select valid dtd type')
    %
end


%% Gain schduling (torque gain normalisation)
if strcmp(dtdParam.convType,'vcsv')
    omega2omega_em = 2;
    omega_em = omega2omega_em * 2*pi/60 * dtdParam.genSpd;
    omegaDes = 2*pi*dtdParam.gridFreq;
elseif strcmp(dtdParam.convType,'gapc')
    omega2omega_em = 1;
    omega_em = omega2omega_em * 2*pi/60 * dtdParam.genSpd;
    omegaDes = 2*pi/60 * dtdParam.ratedSpeed;
end
normTorqueGain = omega_em / omegaDes;

%% Final transfer function

% dyn0(s) = Pdtd(s)/omega_em(s) [W/(rad/s)]
dyn0 = normTorqueGain*dynHpPre*dynDtd;

% dyn1(s) = Pdtd(s)/omega(s) [W/(rad/s)] , omega=genSpd[rad/s]
dyn1 = omega2omega_em * dyn0;

% dyn(s) = Pdtd(s)/w(s) [W/rpm] , w=genSpd[rpm]
dyn = 2*pi/60 * dyn1; 
else

dyn = tf(0,1);

end

dyn.InputName='w';
dyn.OutputName='Pdtd';






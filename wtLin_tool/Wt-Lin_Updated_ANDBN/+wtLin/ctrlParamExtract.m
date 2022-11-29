function [fcp,cp]=ctrlParamExtract(ProdNormal_parm,ProdFast_parm,Pitch_parm)
%Extracts controller parameters from the control and pitch files

fcp=[];
cp=[];

%% Pitch controller non-liniarity

% Scale by 10 as control output of 1 equals a voltage of 10
fcp.pit.GainPositive = Pitch_parm.getParamExactValue('Px_PiPC_PitchServoGainPositive')*10;
fcp.pit.GainNegative = Pitch_parm.getParamExactValue('Px_PiPC_PitchServoGainNegative')*10;
fcp.pit.DeadZoneGain = Pitch_parm.getParamExactValue('Px_PiPC_DeadZoneGain')*10;
fcp.pit.DeadZone = Pitch_parm.getParamExactValue('Px_PiPC_DeadZone')*10;
fcp.pit.DeadZoneOffset = Pitch_parm.getParamExactValue('Px_PiPC_DeadZoneOffset')*10;
fcp.pit.conv_V2deg      = 1;

%fcp.pit.GainPositive = Px_PiPC_PitchServoGainPositive*10;
%fcp.pit.GainNegative = Px_PiPC_PitchServoGainNegative*10;
%fcp.pit.DeadZoneGain = Px_PiPC_DeadZoneGain*10;
%fcp.pit.DeadZone = Px_PiPC_DeadZone*10;
%fcp.pit.DeadZoneOffset = Px_PiPC_DeadZoneOffset*10;
%fcp.pit.conv_V2deg      = 1;

%% FLC controller gains

% Old FLC
%fcp.flc.K_PI = ProdNormal_parm.getParamExactValue('Px_FLC_PICtrlKp'); % [-] Proportional gain for FLC controller
%fcp.flc.tau_i = ProdNormal_parm.getParamExactValue('Px_FLC_PICtrlTi'); % [s] Integral gain gain for FLC controller
%fcp.flc.tau_ref = ProdNormal_parm.getParamExactValue('Px_FLC_GenSpdRefFiltTau'); % Generator speed reference filter time constant

% New FLC v2
fcp.flc.V2 = ProdFast_parm.getParamExactValue('Px_FLC_EnableFLCv2'); % [-] Use FLC V2
fcp.flc.K_PI = ProdFast_parm.getParamExactValue('Px_FLC_SpeedCtrl_Gain'); % [-] Proportional gain for FLC controller
fcp.flc.tau_i = ProdFast_parm.getParamExactValue('Px_FLC_SpeedCtrl_IntegralTime'); % [s] Integral gain gain for FLC controller
fcp.flc.tau_ref = ProdFast_parm.getParamExactValue('Px_FLC_GenSpdRefFiltTau'); % Generator speed reference filter time constant

%% FLC pitch scheduling parameters

% Operation point GS
fcp.flc.OpGainSchK = ProdFast_parm.getParamExactValue('Px_FLC_GainSchK'); % [-] Operation point GS Gain
fcp.flc.OpGainSchThetaMin = ProdFast_parm.getParamExactValue('Px_FLC_GainSchThetaMin'); % [-] Operation point GS min pitch
fcp.flc.OpGainSchTheta = ProdFast_parm.getParamExactValue('Px_FLC_GainSchTheta'); % [-] Operation point GS pitch
fcp.flc.OpGSMax = ProdFast_parm.getParamExactValue('Px_FLC_GainSchMaxGS'); % [-] Maximum Operation GS
fcp.flc.OpPointEstimatorType = ProdFast_parm.getParamExactValue('Px_FLC_OpPointEstimatorType'); % 

% Linear approximation, nominal operation
fcp.flc.Theta_v = ProdFast_parm.getParamExactValue('Px_FLC_PitchNonlinThetaMin'); % [deg] Threshold for pitch gain scheduling
fcp.flc.BasedPdTeta = ProdFast_parm.getParamExactValue('Px_FLC_PowPitchSensitivityOffset'); % [W] Power offset at rated speed for pitch gain scheduling
fcp.flc.SlopedPdTeta = ProdFast_parm.getParamExactValue('Px_FLC_PowPitchSensitivitySlope'); % [W/deg] Power slope at rated speed for pitch gain scheduling

% Linear approximation, derated operation
fcp.flc.BasedPdTeta_derate = ProdFast_parm.getParamExactValue('Px_FLC_PowPitchSensitivityOffsetDerated'); % [W] Power offset at derated speed for pitch gain scheduling
fcp.flc.SlopedPdTeta_derate = ProdFast_parm.getParamExactValue('Px_FLC_PowPitchSensitivitySlopeDerated'); % [W/deg] Power slope at derated speed for pitch gain scheduling
fcp.flc.NomGenSpeedRef = ProdFast_parm.getParamExactValue('Px_FLC_NomGenSpdRef'); % [rpm] Nominal generator speed reference
fcp.flc.DeratedGenSpeed = ProdFast_parm.getParamExactValue('Px_FLC_PowPitchSensitivityDeratedSpd'); % [rpm] Generator speed reference corresponding to derated pith gain scheduling
fcp.flc.DeratedSpdGain = ProdFast_parm.getParamExactValue('Px_FLC_DeratedSpdGain'); % [-] Gain modification depending on speed setpoint

% Online sensitivity
fcp.flc.TrqSens.NomPit2TrqSens = ProdFast_parm.getParamExactValue('Px_FLC_NomPit2TrqSens');
fcp.flc.TrqSens.UpPit2TrqSens = ProdFast_parm.getParamExactValue('Px_FLC_UpPit2TrqSens');
fcp.flc.TrqSens.LoPit2TrqSens = ProdFast_parm.getParamExactValue('Px_FLC_LoPit2TrqSens');
fcp.flc.EnableRotMomentOnlineGainSch = ProdFast_parm.getParamExactValue('Px_FLC_EnableRotMomentOnlineGainSch');

%% FLC Wind speed gain scheduling

fcp.flc.WindGS.GainSchThetaMin = ProdFast_parm.getParamExactValue('Px_FLC_GainSchThetaMin');
fcp.flc.WindGS.GainSchTheta = ProdFast_parm.getParamExactValue('Px_FLC_GainSchTheta');
fcp.flc.WindGS.GainSchK = ProdFast_parm.getParamExactValue('Px_FLC_GainSchK');
fcp.flc.WindGS.GainSchMaxGS = ProdFast_parm.getParamExactValue('Px_FLC_GainSchMaxGS');

%% FATD

fcp.fatd.KpTwrPos = FindParameter(ProdNormal_parm,ProdFast_parm,'Px_FATD_Pitch_KpTwrPos');
fcp.fatd.KpTwrSpd = FindParameter(ProdNormal_parm,ProdFast_parm,'Px_FATD_Pitch_KpTwrSpd');

% Pos gain sch
fcp.fatd.GainSchWind.Wind1 = FindParameter(ProdNormal_parm,ProdFast_parm,'Px_FATD_Pitch_GS_WindSpd_1');
fcp.fatd.GainSchWind.Wind2 = FindParameter(ProdNormal_parm,ProdFast_parm,'Px_FATD_Pitch_GS_WindSpd_2');
fcp.fatd.GainSchWind.Wind3 = FindParameter(ProdNormal_parm,ProdFast_parm,'Px_FATD_Pitch_GS_WindSpd_3');
fcp.fatd.GainSchWind.Wind4 = FindParameter(ProdNormal_parm,ProdFast_parm,'Px_FATD_Pitch_GS_WindSpd_4');
fcp.fatd.GainSchWind.Gain1 = FindParameter(ProdNormal_parm,ProdFast_parm,'Px_FATD_Pitch_GS_Gain_1');
fcp.fatd.GainSchWind.Gain2 = FindParameter(ProdNormal_parm,ProdFast_parm,'Px_FATD_Pitch_GS_Gain_2');
fcp.fatd.GainSchWind.Gain3 = FindParameter(ProdNormal_parm,ProdFast_parm,'Px_FATD_Pitch_GS_Gain_3');
fcp.fatd.GainSchWind.Gain4 = FindParameter(ProdNormal_parm,ProdFast_parm,'Px_FATD_Pitch_GS_Gain_4');

% Vel gain sch
fcp.fatd.GainSchFreq.SwitchOffVelFb = FindParameter(ProdNormal_parm,ProdFast_parm,'Px_FATD_TowFrq_SwitchOffVelFb');
fcp.fatd.GainSchFreq.SwitchOnVelFb = FindParameter(ProdNormal_parm,ProdFast_parm,'Px_FATD_TowFrq_SwitchOnVelFb');
fcp.fatd.GainSchFreq.MinVelFbGain = FindParameter(ProdNormal_parm,ProdFast_parm,'Px_FATD_TowFrq_MinVelFbGain');



%% PLC pitch scheduling parameters

fcp.plc.KP_Nom = ProdFast_parm.getParamExactValue('Px_PLC_PIHighSpdKp');
fcp.plc.KP_Min = ProdFast_parm.getParamExactValue('Px_PLC_PILowSpdKp');
fcp.plc.Ti = ProdFast_parm.getParamExactValue('Px_PLC_PIHighSpdTi');
fcp.plc.GenSpd_Min = ProdFast_parm.getParamExactValue('Px_PLC_Gen1LowSpdRefLim');
fcp.plc.GenSpd_Nom = ProdFast_parm.getParamExactValue('Px_PLC_Gen1HighSpdRefLim');
fcp.plc.tau_ref = ProdFast_parm.getParamExactValue('Px_PLC_GenSpdRefFiltTau');
fcp.plc.tau_mess = ProdFast_parm.getParamExactValue('Px_PLC_GenSpdTau');

%fcp.plc.KP_Nom = Px_PLC_PIHighSpdKp;
%fcp.plc.KP_Min = Px_PLC_PILowSpdKp;
%fcp.plc.Ti = Px_PLC_PIHighSpdTi;
%fcp.plc.GenSpd_Min = Px_PLC_Gen1LowSpdRefLim;
%fcp.plc.GenSpd_Nom = Px_PLC_Gen1HighSpdRefLim;
%fcp.plc.tau_ref = Px_PLC_GenSpdRefFiltTau;
    
%% Band stop filters

fcp.filt.DrvTrnBS1a.Enable = ProdFast_parm.getParamExactValue('Px_SPf_EnableGenSpdBSFilt1a');
fcp.filt.DrvTrnBS1a.FC = ProdFast_parm.getParamExactValue('Px_SPf_GenSpdBSFilt1a_fc');
fcp.filt.DrvTrnBS1a.BW = ProdFast_parm.getParamExactValue('Px_SPf_GenSpdBSFilt1a_bw');

fcp.filt.DrvTrnBS2.Enable = ProdFast_parm.getParamExactValue('Px_SPf_EnableGenSpdBSFilt2');
fcp.filt.DrvTrnBS2.FC = ProdFast_parm.getParamExactValue('Px_SPf_GenSpdBSFilt2_fc');
fcp.filt.DrvTrnBS2.BW = ProdFast_parm.getParamExactValue('Px_SPf_GenSpdBSFilt2_bw');

fcp.filt.DrvTrnBS3.Enable = ProdFast_parm.getParamExactValue('Px_SPf_EnableGenSpdBSFilt3');
fcp.filt.DrvTrnBS3.FC = ProdFast_parm.getParamExactValue('Px_SPf_GenSpdBSFilt3_fc');
fcp.filt.DrvTrnBS3.BW = ProdFast_parm.getParamExactValue('Px_SPf_GenSpdBSFilt3_bw');

%fcp.filt.DrvTrnBS1a.Enable = Px_SPf_EnableGenSpdBSFilt1a;
%fcp.filt.DrvTrnBS1a.FC = Px_SP_GenSpdBSFilt1a_fc;
%fcp.filt.DrvTrnBS1a.BW = Px_SPf_GenSpdBSFilt1a_bw;
%fcp.filt.DrvTrnBS2.Enable = Px_SPf_EnableGenSpdBSFilt2;
%fcp.filt.DrvTrnBS2.FC = Px_SP_GenSpdBSFilt2_fc;
%fcp.filt.DrvTrnBS2.BW = Px_SPf_GenSpdBSFilt2_bw;
%fcp.filt.DrvTrnBS3.Enable = Px_SPf_EnableGenSpdBSFilt3;
%fcp.filt.DrvTrnBS3.FC = Px_SP_GenSpdBSFilt3_fc;
%fcp.filt.DrvTrnBS3.BW = Px_SPf_GenSpdBSFilt3_bw;

% new....
%fcp.filt.DrvTrnBS2ndTow.Enable = Px_SPf_EnableSecondTowFreqFilt;
%fcp.filt.DrvTrnBS2ndTow.FC = Px_SPf_SecondTowFreqFilt_fc;
%fcp.filt.DrvTrnBS2ndTow.BW = Px_SPf_SecondTowFreqFilt_bw;

%% SP

cp.sp.RotorRadius = ProdNormal_parm.getParamExactValue('Px_SP_RotorRadius');


%% HWO operating points
fcp.hwo.Variant1 = ProdNormal_parm.getParamExactValue('Px_LDO_HWO_SelectVersion1');
fcp.hwo.FixedSetPoint = ProdNormal_parm.getParamExactValue('Px_LDO_HWO_FixedSetpointsEnable');
fcp.hwo.WindSpd_NoLimitRef = ProdNormal_parm.getParamExactValue('Px_LDO_HWO_WindSpd_NoLimitRef');

fcp.hwo.wind = zeros(1,9);
fcp.hwo.wind(1,1) = 1.2; 
fcp.hwo.wind(1,2) = 1; 
fcp.hwo.wind(1,3) = ProdNormal_parm.getParamExactValue('Px_LDO_HWO_WindSpd_01'); 
fcp.hwo.wind(1,4) = ProdNormal_parm.getParamExactValue('Px_LDO_HWO_WindSpd_02'); 
fcp.hwo.wind(1,5) = ProdNormal_parm.getParamExactValue('Px_LDO_HWO_WindSpd_03'); 
fcp.hwo.wind(1,6) = ProdNormal_parm.getParamExactValue('Px_LDO_HWO_WindSpd_04'); 
fcp.hwo.wind(1,7) = ProdNormal_parm.getParamExactValue('Px_LDO_HWO_WindSpd_05'); 
fcp.hwo.wind(1,8) = ProdNormal_parm.getParamExactValue('Px_LDO_HWO_WindSpd_06'); 
fcp.hwo.wind(1,9) = ProdNormal_parm.getParamExactValue('Px_LDO_HWO_WindSpd_07'); 

fcp.hwo.genSpd = zeros(1,9);
fcp.hwo.genSpd(1,1) = 1.2; 
fcp.hwo.genSpd(1,2) = 1; 
fcp.hwo.genSpd(1,3) = ProdNormal_parm.getParamExactValue('Px_LDO_HWO_GenSpdRel_01'); 
fcp.hwo.genSpd(1,4) = ProdNormal_parm.getParamExactValue('Px_LDO_HWO_GenSpdRel_02'); 
fcp.hwo.genSpd(1,5) = ProdNormal_parm.getParamExactValue('Px_LDO_HWO_GenSpdRel_03'); 
fcp.hwo.genSpd(1,6) = ProdNormal_parm.getParamExactValue('Px_LDO_HWO_GenSpdRel_04'); 
fcp.hwo.genSpd(1,7) = ProdNormal_parm.getParamExactValue('Px_LDO_HWO_GenSpdRel_05'); 
fcp.hwo.genSpd(1,8) = ProdNormal_parm.getParamExactValue('Px_LDO_HWO_GenSpdRel_06'); 
fcp.hwo.genSpd(1,9) = ProdNormal_parm.getParamExactValue('Px_LDO_HWO_GenSpdRel_07'); 

fcp.hwo.power = zeros(1,9);
fcp.hwo.power(1,1) = 1.2; 
fcp.hwo.power(1,2) = 1; 
fcp.hwo.power(1,3) = ProdNormal_parm.getParamExactValue('Px_LDO_HWO_PowerRel_01'); 
fcp.hwo.power(1,4) = ProdNormal_parm.getParamExactValue('Px_LDO_HWO_PowerRel_02'); 
fcp.hwo.power(1,5) = ProdNormal_parm.getParamExactValue('Px_LDO_HWO_PowerRel_03'); 
fcp.hwo.power(1,6) = ProdNormal_parm.getParamExactValue('Px_LDO_HWO_PowerRel_04'); 
fcp.hwo.power(1,7) = ProdNormal_parm.getParamExactValue('Px_LDO_HWO_PowerRel_05'); 
fcp.hwo.power(1,8) = ProdNormal_parm.getParamExactValue('Px_LDO_HWO_PowerRel_06'); 
fcp.hwo.power(1,9) = ProdNormal_parm.getParamExactValue('Px_LDO_HWO_PowerRel_07'); 

    
%% Optitip curve

cp.otc.tab.lambda = zeros(1,14);
cp.otc.tab.lambda(1,1) = ProdNormal_parm.getParamExactValue('Px_OTC_TableLambdaToPitchOptX01');
cp.otc.tab.lambda(1,2) = ProdNormal_parm.getParamExactValue('Px_OTC_TableLambdaToPitchOptX02');
cp.otc.tab.lambda(1,3) = ProdNormal_parm.getParamExactValue('Px_OTC_TableLambdaToPitchOptX03');
cp.otc.tab.lambda(1,4) = ProdNormal_parm.getParamExactValue('Px_OTC_TableLambdaToPitchOptX04');
cp.otc.tab.lambda(1,5) = ProdNormal_parm.getParamExactValue('Px_OTC_TableLambdaToPitchOptX05');
cp.otc.tab.lambda(1,6) = ProdNormal_parm.getParamExactValue('Px_OTC_TableLambdaToPitchOptX06');
cp.otc.tab.lambda(1,7) = ProdNormal_parm.getParamExactValue('Px_OTC_TableLambdaToPitchOptX07');
cp.otc.tab.lambda(1,8) = ProdNormal_parm.getParamExactValue('Px_OTC_TableLambdaToPitchOptX08');
cp.otc.tab.lambda(1,9) = ProdNormal_parm.getParamExactValue('Px_OTC_TableLambdaToPitchOptX09');
cp.otc.tab.lambda(1,10) = ProdNormal_parm.getParamExactValue('Px_OTC_TableLambdaToPitchOptX10');
cp.otc.tab.lambda(1,11) = ProdNormal_parm.getParamExactValue('Px_OTC_TableLambdaToPitchOptX11');
cp.otc.tab.lambda(1,12) = ProdNormal_parm.getParamExactValue('Px_OTC_TableLambdaToPitchOptX12');
cp.otc.tab.lambda(1,13) = ProdNormal_parm.getParamExactValue('Px_OTC_TableLambdaToPitchOptX13');
cp.otc.tab.lambda(1,14) = ProdNormal_parm.getParamExactValue('Px_OTC_TableLambdaToPitchOptX14');

cp.otc.tab.pitch = zeros(1,14);
cp.otc.tab.pitch(1,1) = ProdNormal_parm.getParamExactValue('Px_OTC_TableLambdaToPitchOptY01');
cp.otc.tab.pitch(1,2) = ProdNormal_parm.getParamExactValue('Px_OTC_TableLambdaToPitchOptY02');
cp.otc.tab.pitch(1,3) = ProdNormal_parm.getParamExactValue('Px_OTC_TableLambdaToPitchOptY03');
cp.otc.tab.pitch(1,4) = ProdNormal_parm.getParamExactValue('Px_OTC_TableLambdaToPitchOptY04');
cp.otc.tab.pitch(1,5) = ProdNormal_parm.getParamExactValue('Px_OTC_TableLambdaToPitchOptY05');
cp.otc.tab.pitch(1,6) = ProdNormal_parm.getParamExactValue('Px_OTC_TableLambdaToPitchOptY06');
cp.otc.tab.pitch(1,7) = ProdNormal_parm.getParamExactValue('Px_OTC_TableLambdaToPitchOptY07');
cp.otc.tab.pitch(1,8) = ProdNormal_parm.getParamExactValue('Px_OTC_TableLambdaToPitchOptY08');
cp.otc.tab.pitch(1,9) = ProdNormal_parm.getParamExactValue('Px_OTC_TableLambdaToPitchOptY09');
cp.otc.tab.pitch(1,10) = ProdNormal_parm.getParamExactValue('Px_OTC_TableLambdaToPitchOptY10');
cp.otc.tab.pitch(1,11) = ProdNormal_parm.getParamExactValue('Px_OTC_TableLambdaToPitchOptY11');
cp.otc.tab.pitch(1,12) = ProdNormal_parm.getParamExactValue('Px_OTC_TableLambdaToPitchOptY12');
cp.otc.tab.pitch(1,13) = ProdNormal_parm.getParamExactValue('Px_OTC_TableLambdaToPitchOptY13');
cp.otc.tab.pitch(1,14) = ProdNormal_parm.getParamExactValue('Px_OTC_TableLambdaToPitchOptY14');



%      cp.otc.tab.lambda=[Px_OTC_TableLambdaToPitchOptX01 ...
%                        Px_OTC_TableLambdaToPitchOptX02 ...
%                        Px_OTC_TableLambdaToPitchOptX03 ...
%                        Px_OTC_TableLambdaToPitchOptX04 ...
%                        Px_OTC_TableLambdaToPitchOptX05 ...
%                        Px_OTC_TableLambdaToPitchOptX06 ...
%                        Px_OTC_TableLambdaToPitchOptX07 ...
%                        Px_OTC_TableLambdaToPitchOptX08 ...
%                        Px_OTC_TableLambdaToPitchOptX09 ...
%                        Px_OTC_TableLambdaToPitchOptX10 ...
%                        Px_OTC_TableLambdaToPitchOptX11 ...
%                        Px_OTC_TableLambdaToPitchOptX12 ...
%                        Px_OTC_TableLambdaToPitchOptX13 ...
%                        Px_OTC_TableLambdaToPitchOptX14];

%      cp.otc.tab.pitch=[Px_OTC_TableLambdaToPitchOptY01 ...
%                        Px_OTC_TableLambdaToPitchOptY02 ...
%                        Px_OTC_TableLambdaToPitchOptY03 ...
%                        Px_OTC_TableLambdaToPitchOptY04 ...
%                        Px_OTC_TableLambdaToPitchOptY05 ...
%                        Px_OTC_TableLambdaToPitchOptY06 ...
%                        Px_OTC_TableLambdaToPitchOptY07 ...
%                        Px_OTC_TableLambdaToPitchOptY08 ...
%                        Px_OTC_TableLambdaToPitchOptY09 ...
%                        Px_OTC_TableLambdaToPitchOptY10 ...
%                        Px_OTC_TableLambdaToPitchOptY11 ...
%                        Px_OTC_TableLambdaToPitchOptY12 ...
%                        Px_OTC_TableLambdaToPitchOptY13 ...
%                        Px_OTC_TableLambdaToPitchOptY14];
                   
%% SC       

cp.sc.LambdaOpt = ProdNormal_parm.getParamExactValue('Px_SC_PartLoadLambdaOpt');
cp.sc.NomSpd = ProdNormal_parm.getParamExactValue('Px_SC_NomTorqueSpd');
cp.sc.MinSpd = ProdNormal_parm.getParamExactValue('Px_SC_GenStarMinStaticSpd');

%cp.sc.LambdaOpt = Px_SC_PartLoadLambdaOpt;
%cp.sc.NomSpd = Px_SC_NomTorqueSpd;
%cp.sc.MinSpd = Px_SC_GenStarMinStaticSpd;
     
%% Thrust Limiter


cp.otc.tl.offset.genSpd = zeros(1,5);
cp.otc.tl.offset.genSpd(1,1) = ProdNormal_parm.getParamExactValue('Px_TL_TableGenSpdToPitchPowOffsetX01');
cp.otc.tl.offset.genSpd(1,2) = ProdNormal_parm.getParamExactValue('Px_TL_TableGenSpdToPitchPowOffsetX02');
cp.otc.tl.offset.genSpd(1,3) = ProdNormal_parm.getParamExactValue('Px_TL_TableGenSpdToPitchPowOffsetX03');
cp.otc.tl.offset.genSpd(1,4) = ProdNormal_parm.getParamExactValue('Px_TL_TableGenSpdToPitchPowOffsetX04');
cp.otc.tl.offset.genSpd(1,5) = ProdNormal_parm.getParamExactValue('Px_TL_TableGenSpdToPitchPowOffsetX05');

cp.otc.tl.offset.pitch = zeros(1,5);
cp.otc.tl.offset.pitch(1,1) = ProdNormal_parm.getParamExactValue('Px_TL_TableGenSpdToPitchPowOffsetY01');
cp.otc.tl.offset.pitch(1,2) = ProdNormal_parm.getParamExactValue('Px_TL_TableGenSpdToPitchPowOffsetY02');
cp.otc.tl.offset.pitch(1,3) = ProdNormal_parm.getParamExactValue('Px_TL_TableGenSpdToPitchPowOffsetY03');
cp.otc.tl.offset.pitch(1,4) = ProdNormal_parm.getParamExactValue('Px_TL_TableGenSpdToPitchPowOffsetY04');
cp.otc.tl.offset.pitch(1,5) = ProdNormal_parm.getParamExactValue('Px_TL_TableGenSpdToPitchPowOffsetY05');

cp.otc.tl.slope.genSpd = zeros(1,5);
cp.otc.tl.slope.genSpd(1,1) = ProdNormal_parm.getParamExactValue('Px_TL_TableGenSpdToPitchPowSlopeX01');
cp.otc.tl.slope.genSpd(1,2) = ProdNormal_parm.getParamExactValue('Px_TL_TableGenSpdToPitchPowSlopeX02');
cp.otc.tl.slope.genSpd(1,3) = ProdNormal_parm.getParamExactValue('Px_TL_TableGenSpdToPitchPowSlopeX03');
cp.otc.tl.slope.genSpd(1,4) = ProdNormal_parm.getParamExactValue('Px_TL_TableGenSpdToPitchPowSlopeX04');
cp.otc.tl.slope.genSpd(1,5) = ProdNormal_parm.getParamExactValue('Px_TL_TableGenSpdToPitchPowSlopeX05');


cp.otc.tl.slope.pitchPkW = zeros(1,5);
cp.otc.tl.slope.pitchPkW(1,1) = ProdNormal_parm.getParamExactValue('Px_TL_TableGenSpdToPitchPowSlopeY01');
cp.otc.tl.slope.pitchPkW(1,2) = ProdNormal_parm.getParamExactValue('Px_TL_TableGenSpdToPitchPowSlopeY02');
cp.otc.tl.slope.pitchPkW(1,3) = ProdNormal_parm.getParamExactValue('Px_TL_TableGenSpdToPitchPowSlopeY03');
cp.otc.tl.slope.pitchPkW(1,4) = ProdNormal_parm.getParamExactValue('Px_TL_TableGenSpdToPitchPowSlopeY04');
cp.otc.tl.slope.pitchPkW(1,5) = ProdNormal_parm.getParamExactValue('Px_TL_TableGenSpdToPitchPowSlopeY05');

cp.otc.NomPow = ProdNormal_parm.getParamExactValue('Px_TL_NomPow');


% cp.otc.tl.offset.genSpd = ...
%     [Px_TL_TableGenSpdToPitchPowOffsetX01 ... 
%     Px_TL_TableGenSpdToPitchPowOffsetX02 ... 
%     Px_TL_TableGenSpdToPitchPowOffsetX03 ... 
%     Px_TL_TableGenSpdToPitchPowOffsetX04 ... 
%     Px_TL_TableGenSpdToPitchPowOffsetX05];
% 
% cp.otc.tl.offset.pitch = ... 
%     [Px_TL_TableGenSpdToPitchPowOffsetY01 ...
%     Px_TL_TableGenSpdToPitchPowOffsetY02 ...
%     Px_TL_TableGenSpdToPitchPowOffsetY03 ...   
%     Px_TL_TableGenSpdToPitchPowOffsetY04 ...
%     Px_TL_TableGenSpdToPitchPowOffsetY05];
%                   
% cp.otc.tl.slope.genSpd = ... 
%     [Px_TL_TableGenSpdToPitchPowSlopeX01 ...
%     Px_TL_TableGenSpdToPitchPowSlopeX02 ...                            
%     Px_TL_TableGenSpdToPitchPowSlopeX03 ...
%     Px_TL_TableGenSpdToPitchPowSlopeX04 ...
%     Px_TL_TableGenSpdToPitchPowSlopeX05];
%                         
% cp.otc.tl.slope.pitchPkW = ... 
%     [Px_TL_TableGenSpdToPitchPowSlopeY01 ...   
%     Px_TL_TableGenSpdToPitchPowSlopeY02 ...
%     Px_TL_TableGenSpdToPitchPowSlopeY03 ...
%     Px_TL_TableGenSpdToPitchPowSlopeY04 ...
%     Px_TL_TableGenSpdToPitchPowSlopeY05];
%     
% cp.otc.NomPow=Px_TL_NomPow;


%% Supporting functions
function Out = FindParameter(ProdNormal_parm,ProdFast_parm,param)
    if ~isempty(ProdNormal_parm.getParamExactValue(param))
        Out = ProdNormal_parm.getParamExactValue(param);
    else
        Out = ProdFast_parm.getParamExactValue(param);
    end

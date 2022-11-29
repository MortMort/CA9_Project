function [fcp,cp]=cpExtract(ControlFile,PitchFile)
%Extracts controller parametersfrom the control and pitch files
   
%JADGR, Mar 2012
    
    %Fix true and false
    False=false;
    True=true;


    run(PitchFile)
    
    %% Pitch controller non-liniarity
%     
    %Scale by 10 as control output of 1 equals a voltage of 10
    if (exist('Px_PitchServoGainPositive'))
        fcp.pit.GainPositive    = Px_PitchServoGainPositive*10;
        fcp.pit.GainNegative    = Px_PitchServoGainNegative*10;
        fcp.pit.DeadZoneGain    = Px_DeadZoneGain*10;
        fcp.pit.DeadZone        = Px_DeadZone*10;
        fcp.pit.DeadZoneOffset  = Px_DeadZoneOffset*10;
        fcp.pit.conv_V2deg      = Px_Pit_ConvV2Deg;
        
    elseif (exist('Px_PiPC_PitchServoGainPositive'))
        fcp.pit.GainPositive    = Px_PiPC_PitchServoGainPositive*10;
        fcp.pit.GainNegative    = Px_PiPC_PitchServoGainNegative*10;
        fcp.pit.DeadZoneGain    = Px_PiPC_DeadZoneGain*10;
        fcp.pit.DeadZone        = Px_PiPC_DeadZone*10;
        fcp.pit.DeadZoneOffset  = Px_PiPC_DeadZoneOffset*10;
        fcp.pit.conv_V2deg      = 1;
    else
        fcp.pit.GainPositive    = 0.3*10;
        fcp.pit.GainNegative    = 0.3*10;
        fcp.pit.DeadZoneGain    = 1.43;
        fcp.pit.DeadZone        = 0.2;
        fcp.pit.DeadZoneOffset  = -0.01;
        fcp.pit.conv_V2deg      = 1;
        warning('Unsupported controller version, Pitch model will not work')
    end
    run(ControlFile);

    %% FLC controller gains
    fcp.flc.K_PI=Px_FLC_PICtrlKp;%/fcp.pit.conv_V2deg; % [-] Proportional gain for FLC controller
    fcp.flc.tau_i=Px_FLC_PICtrlTi;% [s] Integral gain gain for FLC controller
    fcp.flc.tau_ref=Px_FLC_GenSpdRefFiltTau; %Generator speed reference filter time constant
       
    %% FLC pitch scheduling parameters
    fcp.flc.Theta_v=Px_FLC_PitchNonlinThetaMin;                         % [deg] Threshold for pitch gain scheduling
    fcp.flc.BasedPdTeta=Px_FLC_PowPitchSensitivityOffset;               % [W] Power offset at rated speed for pitch gain scheduling
    fcp.flc.SlopedPdTeta=Px_FLC_PowPitchSensitivitySlope;               % [W/deg] Power slope at rated speed for pitch gain scheduling
    
    %% Pitch GS at derated speed
    if exist('Px_FLC_PowPitchSensitivityOffsetDerated','var')    
        fcp.flc.BasedPdTeta_derate=Px_FLC_PowPitchSensitivityOffsetDerated; % [W] Power offset at derated speed for pitch gain scheduling
        fcp.flc.SlopedPdTeta_derate=Px_FLC_PowPitchSensitivitySlopeDerated; % [W/deg] Power slope at derated speed for pitch gain scheduling

        fcp.flc.NomGenSpeedRef=Px_FLC_NomGenSpdRef;                         % [rpm] Nominal generator speed reference
        fcp.flc.DeratedGenSpeed=Px_FLC_PowPitchSensitivityDeratedSpd;       % [rpm] Generator speed reference corresponding to derated pith gain scheduling
        fcp.flc.DeratedSpdGain=Px_FLC_DeratedSpdGain;                           % [-] Gain modification depending on speed setpoint
    end
    
    fcp.plc.KP_Nom=Px_PLC_PIHighSpdKp;
    fcp.plc.KP_Min=Px_PLC_PILowSpdKp;
    fcp.plc.Ti=Px_PLC_PIHighSpdTi;
    fcp.plc.GenSpd_Min=Px_PLC_Gen1LowSpdRefLim;
    fcp.plc.GenSpd_Nom=Px_PLC_Gen1HighSpdRefLim;
    fcp.plc.tau_ref=Px_PLC_GenSpdRefFiltTau;
    
    if exist('Px_BWF_BandStopPart1_DenA1','var') 
        %Band stop filter coefficients
        cp.filt.den11=[Px_BWF_BandStopPart1_DenA1 ...
                       Px_BWF_BandStopPart1_DenA2 ...
                       Px_BWF_BandStopPart1_DenA3];
                
        cp.filt.num11=[Px_BWF_BandStopPart1_NumB1 ...
                       Px_BWF_BandStopPart1_NumB2 ...
                       Px_BWF_BandStopPart1_NumB3];
                
        cp.filt.den21=[Px_BWF_BandStopPart2_DenA1 ...
                       Px_BWF_BandStopPart2_DenA2 ...
                       Px_BWF_BandStopPart2_DenA3];
                
        cp.filt.num21=[Px_BWF_BandStopPart2_NumB1 ...
                       Px_BWF_BandStopPart2_NumB2 ...
                       Px_BWF_BandStopPart2_NumB3];
    end      
    
    if exist('Px_SP_EnableGenSpdBSFilt1a','var')
        fcp.filt.DrvTrnBS1a.Enable=Px_SP_EnableGenSpdBSFilt1a;
        fcp.filt.DrvTrnBS2.Enable=Px_SP_EnableGenSpdBSFilt2;
        fcp.filt.DrvTrnBS3.Enable=Px_SP_EnableGenSpdBSFilt3;
        
        fcp.filt.DrvTrnBS1a.BW=Px_SP_GenSpdBSFilt1a_bw;
        fcp.filt.DrvTrnBS2.BW=Px_SP_GenSpdBSFilt2_bw;
        fcp.filt.DrvTrnBS3.BW=Px_SP_GenSpdBSFilt3_bw;
        
        fcp.filt.DrvTrnBS1a.FC=Px_SP_GenSpdBSFilt1a_fc;
        fcp.filt.DrvTrnBS2.FC=Px_SP_GenSpdBSFilt2_fc;
        fcp.filt.DrvTrnBS3.FC=Px_SP_GenSpdBSFilt3_fc;      
    end
                
   if exist('Px_SP_EnableGenSpdDrvTrn2ndModeBSfilt','var')          
    
       cp.filt.DrvTrnBSden1=[Px_SP_GenSpdDrvTrnBSFiltPart1A0 ...
                             Px_SP_GenSpdDrvTrnBSFiltPart1A1 ...
                             Px_SP_GenSpdDrvTrnBSFiltPart1A2];

       cp.filt.DrvTrnBSnum1=[Px_SP_GenSpdDrvTrnBSFiltPart1B0 ...
                            Px_SP_GenSpdDrvTrnBSFiltPart1B1 ...
                            Px_SP_GenSpdDrvTrnBSFiltPart1B2];

       cp.filt.DrvTrnBSnum2=[Px_SP_GenSpdDrvTrnBSFiltPart2B0 ...
                            Px_SP_GenSpdDrvTrnBSFiltPart2B1 ...
                            Px_SP_GenSpdDrvTrnBSFiltPart2B2];

       cp.filt.DrvTrnBSden2=[Px_SP_GenSpdDrvTrnBSFiltPart2A0 ...
                            Px_SP_GenSpdDrvTrnBSFiltPart2A1 ...
                            Px_SP_GenSpdDrvTrnBSFiltPart2A2];

       cp.filt.EnableDrvTrnBS =Px_SP_EnableGenSpdDrvTrn2ndModeBSfilt;
   else
       cp.filt.EnableDrvTrnBS =0;
   end
                    
    %% HWO operating points
    if exist('Px_HWO_WindThreshold1','var')
        fcp.hwo.wind=[Px_HWO_WindThreshold1 Px_HWO_WindThreshold2 Px_HWO_WindThreshold3 Px_HWO_WindThreshold4 Px_HWO_WindThreshold5];
        fcp.hwo.genSpd=[Px_HWO_GenSpdMode01  Px_HWO_GenSpdMode02  Px_HWO_GenSpdMode03  Px_HWO_GenSpdMode04  Px_HWO_GenSpdMode05];
        fcp.hwo.power=[Px_HWO_PowMode01    Px_HWO_PowMode02     Px_HWO_PowMode03     Px_HWO_PowMode04     Px_HWO_PowMode05];
    end

    
    %Optitip curve
    cp.otc.tab.lambda=[Px_OTC_TableLambdaToPitchOptX01 ...
                       Px_OTC_TableLambdaToPitchOptX02 ...
                       Px_OTC_TableLambdaToPitchOptX03 ...
                       Px_OTC_TableLambdaToPitchOptX04 ...
                       Px_OTC_TableLambdaToPitchOptX05 ...
                       Px_OTC_TableLambdaToPitchOptX06 ...
                       Px_OTC_TableLambdaToPitchOptX07 ...
                       Px_OTC_TableLambdaToPitchOptX08 ...
                       Px_OTC_TableLambdaToPitchOptX09 ...
                       Px_OTC_TableLambdaToPitchOptX10 ...
                       Px_OTC_TableLambdaToPitchOptX11 ...
                       Px_OTC_TableLambdaToPitchOptX12 ...
                       Px_OTC_TableLambdaToPitchOptX13 ...
                       Px_OTC_TableLambdaToPitchOptX14];


     cp.otc.tab.pitch=[Px_OTC_TableLambdaToPitchOptY01 ...
                       Px_OTC_TableLambdaToPitchOptY02 ...
                       Px_OTC_TableLambdaToPitchOptY03 ...
                       Px_OTC_TableLambdaToPitchOptY04 ...
                       Px_OTC_TableLambdaToPitchOptY05 ...
                       Px_OTC_TableLambdaToPitchOptY06 ...
                       Px_OTC_TableLambdaToPitchOptY07 ...
                       Px_OTC_TableLambdaToPitchOptY08 ...
                       Px_OTC_TableLambdaToPitchOptY09 ...
                       Px_OTC_TableLambdaToPitchOptY10 ...
                       Px_OTC_TableLambdaToPitchOptY11 ...
                       Px_OTC_TableLambdaToPitchOptY12 ...
                       Px_OTC_TableLambdaToPitchOptY13 ...
                       Px_OTC_TableLambdaToPitchOptY14];
                   
            
                   
      
     cp.sc.LambdaOpt=Px_SC_PartLoadLambdaOpt;
     cp.sc.NomSpd=Px_SC_NomTorqueSpd;
     cp.sc.MinSpd=Px_SC_GenStarMinStaticSpd;
     
    %Thrust-limiter
    cp.otc.tl.offset.genSpd=[Px_TL_TableGenSpdToPitchPowOffsetX01 ...       
                      Px_TL_TableGenSpdToPitchPowOffsetX02 ...
                      Px_TL_TableGenSpdToPitchPowOffsetX03 ...
                      Px_TL_TableGenSpdToPitchPowOffsetX04 ...
                      Px_TL_TableGenSpdToPitchPowOffsetX05];
    
    
    
    cp.otc.tl.offset.pitch=[Px_TL_TableGenSpdToPitchPowOffsetY01 ...
                      Px_TL_TableGenSpdToPitchPowOffsetY02 ...
                      Px_TL_TableGenSpdToPitchPowOffsetY03 ...   
                      Px_TL_TableGenSpdToPitchPowOffsetY04 ...
                      Px_TL_TableGenSpdToPitchPowOffsetY05];
                  
    cp.otc.tl.slope.genSpd=[Px_TL_TableGenSpdToPitchPowSlopeX01 ...
                            Px_TL_TableGenSpdToPitchPowSlopeX02 ...                            
                            Px_TL_TableGenSpdToPitchPowSlopeX03 ...
                            Px_TL_TableGenSpdToPitchPowSlopeX04 ...
                            Px_TL_TableGenSpdToPitchPowSlopeX05];
                        
    cp.otc.tl.slope.pitchPkW=[Px_TL_TableGenSpdToPitchPowSlopeY01 ...   
                              Px_TL_TableGenSpdToPitchPowSlopeY02 ...
                              Px_TL_TableGenSpdToPitchPowSlopeY03 ...
                              Px_TL_TableGenSpdToPitchPowSlopeY04 ...
                              Px_TL_TableGenSpdToPitchPowSlopeY05];
    
    cp.otc.NomPow=Px_TL_NomPow;

end
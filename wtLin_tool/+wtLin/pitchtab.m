function [theta_err, Uctrl] = pitchtab(pit)
% Computes pitch table from controller parameters

%Version history – Responsible JADGR
%Original by THK from integration test2 scripts Extracted for the purposes
%of parameter reader
%V0 - 01-0-2012 - JADGR 


GainNeg=pit.GainNegative;
GainPos=pit.GainPositive;
DZone=pit.DeadZone;
DZoneGain=pit.DeadZoneGain;
DZoneOff=pit.DeadZoneOffset;
Uctrl_min=pit.MinOutVolt;
Uctrl_max=pit.MaxOutVolt;
V2deg=pit.conv_V2deg;

theta_err_min = -10;
theta_err_max =  10;

EndDeadZonePosVolt = DZone/2 + DZoneOff;
EndDeadZoneNegVolt = -DZone/2 + DZoneOff;

EndDeadZonePosDeg = V2deg * DZone/(2*DZoneGain);
EndDeadZoneNegDeg = -V2deg * DZone/(2*DZoneGain);

EndPitchServoGainPosDeg = V2deg * (Uctrl_max-EndDeadZonePosVolt) / GainPos ...
    + EndDeadZonePosDeg;
EndPitchServoGainNegDeg = V2deg * (Uctrl_min-EndDeadZoneNegVolt) / GainNeg ...
    + EndDeadZoneNegDeg;

theta_err = [theta_err_min EndPitchServoGainNegDeg EndDeadZoneNegDeg ...
        EndDeadZonePosDeg EndPitchServoGainPosDeg theta_err_max]';
Uctrl = [Uctrl_min Uctrl_min EndDeadZoneNegVolt EndDeadZonePosVolt ... 
        Uctrl_max Uctrl_max]';
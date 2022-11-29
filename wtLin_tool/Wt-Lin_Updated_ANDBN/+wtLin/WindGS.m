function gain = WindGS(theta,flc)
%Computes the wind dependent gain for the FLC

% Version history – Responsible JSTHO
% V0 - 15-08-2017 - JSTHO

% V1 - 30-09-2022 - ANDBN
% Update to include FLC v2 not using Wind GS

if ~flc.V2
    ThetaMin = flc.WindGS.GainSchThetaMin;
    ThetaGS = flc.WindGS.GainSchTheta;
    K = flc.WindGS.GainSchK;
    MaxGS = flc.WindGS.GainSchMaxGS;

    if (ThetaGS > ThetaMin)
        %
        slope = (1-K)/(ThetaMin-ThetaGS);
        offset = K - slope * ThetaGS;
        %
    else
        slope = 0;
        offset = 1;
    end

    g = slope*theta + offset;
    gain = min(max(1,g),MaxGS);
else
    gain = 1;
end








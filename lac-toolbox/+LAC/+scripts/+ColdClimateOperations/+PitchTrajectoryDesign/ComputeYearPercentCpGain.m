function [YearPercentCpGain] = ComputeYearPercentCpGain(k, Vavg, csvPath, CpGainPercentLight,IdxLbdOpt,LambdaOpt)

csv_norm_par    = LAC.vts.convert(csvPath);
TSR  = 3:13;

% Rated wind speed
GearRatio = csv_norm_par.values(not(cellfun('isempty',strfind(csv_norm_par.parameters, 'Px_SRS_GearRatio'))));
Radius = csv_norm_par.values(not(cellfun('isempty',strfind(csv_norm_par.parameters, 'Px_SC_RotorRadius'))));
RatedRotTipSpd = csv_norm_par.values(not(cellfun('isempty',strfind(csv_norm_par.parameters, 'Px_SP_RatedSpeed'))))*Radius/GearRatio;

RatedWindSpd = RatedRotTipSpd/LambdaOpt;

% Minimum speed at nominal tsr
MinStaticTipSpd = csv_norm_par.values(not(cellfun('isempty',strfind(csv_norm_par.parameters, 'Px_LSO_GenStarMinStaticSpd'))));
MinStaticTipSpd = max([MinStaticTipSpd csv_norm_par.values(not(cellfun('isempty',strfind(csv_norm_par.parameters, 'Px_LSO_GenDeltaMinStaticSpd'))))])*0.1047*Radius/GearRatio;

MinWindSpdAtNomTSR = MinStaticTipSpd/LambdaOpt;

% Cut-in wind speed
CutInWindSpd = MinStaticTipSpd/TSR(end);

% Cut-out wind speed
CutOutWindSpd = RatedRotTipSpd/TSR(1);

% Translate lambda into wind speed
WindInterp = interp1([TSR(end) LambdaOpt+0.01 LambdaOpt TSR(1)],[CutInWindSpd MinWindSpdAtNomTSR RatedWindSpd CutOutWindSpd], TSR);

% Non-NaN CpGainIndices
NotNaNCpGP = CpGainPercentLight(~isnan(CpGainPercentLight));
NotNaNWndInterp = WindInterp(~isnan(CpGainPercentLight));
WindInterp = linspace(max(NotNaNWndInterp),min(NotNaNWndInterp),15);
CpGainPercentInterp = interp1(NotNaNWndInterp,NotNaNCpGP,WindInterp);
WSbin = diff(WindInterp);


C = Vavg/gamma(1+1/k);
pdf = k / C * (WindInterp/C).^(k - 1) .* exp(-(WindInterp/C).^(k));

YearPercentCpGainPdf = CpGainPercentInterp .* pdf;
YearPercentCpGainDens = 0.5*(YearPercentCpGainPdf(2:end) + YearPercentCpGainPdf(1:end-1)).*WSbin;
YearPercentCpGain = sum(YearPercentCpGainDens)./sum(WSbin.*(pdf(2:end)+pdf(1:end-1))*0.5);
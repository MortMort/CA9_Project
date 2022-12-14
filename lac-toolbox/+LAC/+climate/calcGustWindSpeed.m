function [gustWindSpeed,gust_tenMinutWindSpeed_Ratio] = calcGustWindSpeed(tenMinute_windSpeed,referenceTurbulenceIntensity,gustDuration)

% calcGustWindSpeed - Gust Wind Speed for Selected Averaging Period
% Reference: API Recommended Practice 2A (RP 2A), 19´th edition, August 1, 1991
% For more information : Loads and Performance Engineering / LPE - 88
%
% Syntax:  [output1,output2] = function_name(tenMinute_windSpeed,referenceTurbulenceIntensity,gustDuration)
%
% Inputs:
%    tenMinute_windSpeed - 10-min wind speed [m/s].
%    referenceTurbulenceIntensity - Reference Turbulence Intensity, Expected value of hub-height turbulence intensity at a 10 min average wind speed of 15 m/s [%].
%    gustDuration - Gust Duration [s].
%
% Outputs:
%    gustWindSpeed - Gust wind speed [m/s].
%    gust_tenMinutWindSpeed_Ratio - Ratio between gust and 10 min wind speed.
%
% Example:
%  Input:
%   tenMinute_windSpeed = 10;
%   referenceTurbulenceIntensity = 14;
%   gustDuration = 3;
%   [gustWindSpeed,gust_tenMinutWindSpeed_Ratio] = calcGustWindSpeed(tenMinute_windSpeed,referenceTurbulenceIntensity,gustDuration)
%
%  Ouput:
%   gustWindSpeed   = 14.5719
%   gust_tenMinutWindSpeed_Ratio   = 1.4572
%
% Revision History:
% 00: New script by ASKNE [04-Sept-2017]
% 01: Replace Turbulence Intensity [%] with Reference Turbulence Intensity [%]
%
% Review:
% 00:
% 01:
% Author: ASKNE, Ashok Kumar Nedumaran
% September 2017; Last revision: 09-Nov-2017
%
% Other m-files required: none
% Subfunctions: none
% MAT-files required: none
%------------- BEGIN CODE --------------

% Convert Reference Turbulence Intensity to Turbulence Intensity at given wind speed.
representativeStandardDeviation = referenceTurbulenceIntensity * (0.75 * tenMinute_windSpeed + 5.6);
turbulenceIntensityPercentage = representativeStandardDeviation ./ tenMinute_windSpeed;

% Change from Percentage to Fraction
turbulenceIntensity = turbulenceIntensityPercentage/100;

% Calculate gust factor.
gustFactor = 3.0 + log((3/gustDuration)^0.6);

% Calculate gust wind speed.
gustWindSpeed = 0.94 * tenMinute_windSpeed * (1 + gustFactor*turbulenceIntensity);

% Calculate gust wind speed to ten minute wind speed ratio.
gust_tenMinutWindSpeed_Ratio = 0.94 *  (1 + gustFactor*turbulenceIntensity);

end
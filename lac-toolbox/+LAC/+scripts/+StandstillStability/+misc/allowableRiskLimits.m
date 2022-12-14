function [limit] = allowableRiskLimits
% Script defining and returning allowable risk limits.
% See LAC wiki for description.

% general limits
generic = struct('wsp',            {[5:1:25],              [5:1:25],               [15:1:35]},...
             'zfac',           {[ones(1,21)*0.04],     [ones(1,21)*0.06],      [linspace(0,.2,21)]},...
             'service_type',   {1,                     2,                      3},...
             'description',    {{'Rotor locked with all blades in parked/idle position.',...
             'Rotor locked with two blades in parked/idle position, one misaligned.',...
             'Idling i.e. rotor not locked.'}});
                 
% if upwind yaw control (UYC)
uyc = struct('wsp',            {[5:1:25],              [5:1:25],               [15:1:35]},...
             'zfac',           {[ones(1,21)*0.01],     [ones(1,21)*0.04],     [ones(1,21)*0.01]},...
             'service_type',   {1,                     2,                      3},...
             'description',    {{'Rotor locked with all blades in parked/idle position.',...
             'Rotor locked with two blades in parked/idle position, one misaligned.',...
             'Idling i.e. rotor not locked.'}});
         
limit.uyc = uyc;
limit.generic = generic;
                 
end
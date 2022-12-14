function gustWindSpeed = calcGustWsp(gustDuration,tenMinute_windSpeed,TI)
% Approximating gust wind speed based on 10 minute mean wind and turbulence
% intensity.
gustFactor = 3.0 + log((3/gustDuration)^.6);
gustWindSpeed = 0.94 * tenMinute_windSpeed * (1 + gustFactor*TI);
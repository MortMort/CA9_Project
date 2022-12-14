function [powerOutput, stdOutput] = addturbulence(power, windSpeed, rotorDiameter, turbulenceIntensity,Extrap)
% [powerOutput, stdOutput] = LAC.climate.addturbulence(power, windSpeed, rotorDiameter, turbulenceIntensity,Extrap)
% Function that adds the effect of turbulence on Input
%
% Input
%   power:                  Power vector containing data to have turbulenceIntensity effect added (without )
%   windSpeed:              Wind speed vector for power
%   rotorDiameter:          Rotor Diameter
%   turbulenceIntensity:    Turbulence intensity vector for power
%   Extrap                  0 = No correction; 1 = Probability scaling; 2= Endpoint
%
% Output:
%   powerOutput:        power with the effect of turbulenceIntensity added
%   stdOutput:          standard deviation of the added turbulenceIntensity effect.

turbulenceIntensityCorrected = 1.713*rotorDiameter^-0.2115;

deltaWindSpeed = windSpeed(2)-windSpeed(1);

[powerOutput,stdOutput] = deal(zeros(size(power)));

for i=1:length(windSpeed)
    weights=  (0.5*(1+erf((windSpeed-windSpeed(i)+deltaWindSpeed/2)/sqrt(2*(turbulenceIntensity(i)*turbulenceIntensityCorrected*windSpeed(i))^2)))...
        -0.5*(1+erf((windSpeed-windSpeed(i)-deltaWindSpeed/2)/sqrt(2*(turbulenceIntensity(i)*turbulenceIntensityCorrected*windSpeed(i))^2))))';
    switch Extrap
        case 0
            powerOutput(i)=power*weights;
            stdOutput(i)=sqrt(sum((power-powerOutput(i)).^2.*weights'));
        case 1
            weights=weights./sum(weights);
            powerOutput(i)=power*weights;
            stdOutput(i)=sqrt(sum((power-powerOutput(i)).^2.*weights'));
        case 2
            if weights(1)>weights(end)
                weights(1)=weights(1)+1-sum(weights);
            else
                weights(end)=weights(end)+1-sum(weights);
            end
            powerOutput(i)=power*weights;
            stdOutput(i)=sqrt(sum((power-powerOutput(i)).^2.*weights'));
    end
end

end


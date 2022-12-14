close all; clear all;
WS = 20;
RPM = 18;

setupFn        = 'SetupStability.txt';
leg.current    = 'V110 Mk10C Single Web (X3)';

compareSetupfile = {'h:\2MW\MK10C\V110\Investigations\44_SingleWeb_StabilityAssessment\Iter00_Stability_of_Reference_Blade\Stability\SetupAll_v002.txt'};
leg.compare      = {'V110 Mk10C, GS costout'};

stabilityLevel = 'level2'; %level1 = HS2 campbell + HS2 speedup; level2 = level1 + HAWC2 speedup


%%
simdir    = pwd;
currentSetupfile = fullfile(simdir,'Stability',setupFn);

% Read Setupfile
Setup = Stability.common.Setup;
Setup.setupFile = currentSetupfile;
Setup.toolName  = 'none';
disp('read setup file')
SetupInfo.current = Stability.common.readsetupfile(Setup);

%% Initialize comparison
iFig=1;
for iPaths = 1:length(compareSetupfile)
    % Read Compare Setupfile
    Setup.setupFile = compareSetupfile{iPaths};
    disp('read setup file')
    SetupInfo.compare{iPaths} = Stability.common.readsetupfile(Setup);
end
outputfolder = fullfile(simdir,'Stability','Outputs');
mkdir(outputfolder)

%% HAWCStab Comparison
Turbine = Stability.HS2Sim.Turbine;

HS2.current  = Turbine.getturbine(fullfile(simdir,'Stability','HAWCStab2_speedup','Outputs','allTurbineData.mat'));
for iCompare = 1:length(SetupInfo.compare)
    HS2.compare{iCompare}  = Turbine.getturbine(fullfile(SetupInfo.compare{iCompare}.workingPath,'HAWCStab2_speedup','Outputs','allTurbineData.mat'));
end
%%
iWS = find(HS2.current.windSpeedArray==WS);

obj.Turbine = HS2.current;
nSetpoint = obj.Turbine.HS2out{iWS}.CMB.nSetpoints;

nrOfColors = 20;
cmap = jet(nrOfColors);

LAC.figure
subplot(311)
for iSetpoint = 1:nSetpoint

if ~isempty(obj.Turbine.HS2out{iWS}.IND{iSetpoint})
    plot(obj.Turbine.HS2out{iWS}.IND{iSetpoint}.Data.s, LAC.rad2deg(obj.Turbine.HS2out{iWS}.IND{iSetpoint}.Data.Tors),'color', cmap(iSetpoint,:)); hold on
end

end
suptitle(sprintf('Wind Speed %i m/s',round(obj.Turbine.HS2out{iWS}.CMB.windspeed(1))))
xlabel('Radius [m]'); ylabel('Twist [deg]')
grid on;

subplot(312)
for iSetpoint = 1:nSetpoint

if ~isempty(obj.Turbine.HS2out{iWS}.IND{iSetpoint})
    plot(obj.Turbine.HS2out{iWS}.IND{iSetpoint}.Data.s, obj.Turbine.HS2out{iWS}.IND{iSetpoint}.Data.UY0,'color', cmap(iSetpoint,:)); hold on
end

end
grid on;
suptitle(sprintf('Wind Speed %i m/s',round(obj.Turbine.HS2out{iWS}.CMB.windspeed(1))))
xlabel('Radius [m]'); ylabel('Deflection [m]')

subplot(313)
for iSetpoint = 1:nSetpoint

if ~isempty(obj.Turbine.HS2out{iWS}.IND{iSetpoint})
    plot(obj.Turbine.HS2out{iWS}.IND{iSetpoint}.Data.s, obj.Turbine.HS2out{iWS}.IND{iSetpoint}.Data.Y_AC0,'color', cmap(iSetpoint,:)); hold on
end

end
grid on;
suptitle(sprintf('Wind Speed %i m/s',round(obj.Turbine.HS2out{iWS}.CMB.windspeed(1))))
xlabel('Radius [m]'); ylabel('Aero centre position [m]')

LAC.figure
for iSetpoint = 1:nSetpoint

if ~isempty(obj.Turbine.HS2out{iWS}.IND{iSetpoint})
    plot(obj.Turbine.HS2out{iWS}.IND{iSetpoint}.Data.s, obj.Turbine.HS2out{iWS}.IND{iSetpoint}.Data.ALPHA0,'color', cmap(iSetpoint,:)); hold on
end

end
grid on;
suptitle(sprintf('Wind Speed %i m/s',round(obj.Turbine.HS2out{iWS}.CMB.windspeed(1))))
xlabel('Radius [m]'); ylabel('Aero centre position [m]')
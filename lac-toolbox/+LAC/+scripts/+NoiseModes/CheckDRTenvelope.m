function CheckDRTenvelope(folders, drtEnvelope, lgd)
% Function to plot drivetrain envelope and check if MyMbr values from DLC 1.1 are within the envelope
% More info can be found in the Noise Modes Guideline (0073-8946.V03)
% 
% SYNTAX:
% 	LAC.scripts.NoiseModes.CheckDRTenvelope(folders, drtEnvelope, lgd)
%
% INPUTS:
% 	folders - Cell with full paths to Loads folders, containing DLC 1.1 (ex: {'...\Loads\', '..\Loads\'})
% 	drtEnvelope - Vector (nx2) with DRT envelope values (format: col#1 - Omega (LSS), rpm; col#2 - MyMBr, kNm)
% 	lgd - Cell with legend entries for the Loads folders given as input, for the plots (ex: {'SO2', 'SO3'})
%
% OUTPUTS:
% 	Plot of MyMBr values from input Loads folders and DRT envelope
%
% VERSIONS:
% 	2021/09/04 - AAMES: V00

%% CREATE FIG, PLOT ENVELOPE
lgd = ['DRT Envelope' lgd];
figTorque = figure('Name','MyMBr - Torque Envelope');
plot(drtEnvelope(:,1),drtEnvelope(:,2),'-k','LineWidth',1.5);
hold on
grid on
%% READ STAs, PLOT ENVELOPE
markers = {'*','o','^','d','x','h','v','s','<','>'};
sensorTorque = 'MyMBr';
for i = 1:length(folders)
    % Read STAs
    StaObj = LAC.vts.stapost(folders{i});
    StaObj.read();
    sensors = StaObj.stadat.sensor;
    % Find DLC 1.1
    lcsInd = find(~cellfun(@isempty,regexp([StaObj.stadat.filenames],'^11','match')));
    % Find MyMbr
    sensInd = find(~cellfun(@isempty,regexp(sensors,sensorTorque,'match')));
    % Find Omega
    omegaInd = find(~cellfun(@isempty,regexp(sensors,'Omega','match')));
    % calc Fam method
    if ~any(contains(fields(StaObj.stadat),'meanFamily'))
        StaObj.calcFamily();
    end
    meanFam = StaObj.stadat.meanFamily(sensInd,lcsInd);
    meanFamOmega = StaObj.stadat.meanFamily(omegaInd,lcsInd);
    % Plot mean MyMBr
    figure(figTorque)
    plot(meanFamOmega,meanFam,markers{i},'markersize',6,'linewidth',1.4)   
end
legend(lgd,'location','eastoutside');
xlabel('Omega [rpm]')
ylabel('MyMBr [kNm]')
end


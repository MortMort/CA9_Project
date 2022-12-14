function plotCampbell(path)

addpath('W:\ToolsDevelopment\VStab\CURRENT\SOURCE\');
addpath('C:\VestasToolbox\TLtoolbox\Programs\CampbellDiagram\');

load(fullfile(path,'VStab_NormalOperation.mat'))

[Args,STA]=LAC.vstab.prepvstab(path);

% Mode tracker
[freq,Modes.WS,ntfreq,rpm,ntrpm]=modetrack(1,Res.eigvals,Res.eigvec,Info.configlab,Res.evblades);

% Add NaN in freq which are incomplete because of the tracking
MaxNbrWS = 0;
for i=1:length(freq)
    MaxNbrWS = max([MaxNbrWS length(freq{i})]);
end
for i=1:length(freq)
    if length(freq{i})<MaxNbrWS
        freq{i} = [freq{i} repmat(NaN,1,MaxNbrWS-length(freq{i}))];
    end
end

% Eigenfrequencies of each mode in Res (used in GUI to track back the modes)
for i=1:length(Res.eigvals{1})
    for j=1:length(Res.eigvals)
        Res.freq(i,j) = abs(imag(Res.eigvals{j}(i)))/2/pi;
    end
end

% sort tracked modes wrt min and max damped frequency and calculate frequency and damping ratio for plotting
min_freq = 0;     % [Hz] make sure this is below the 1st tower bending eigenfrequencies
max_freq = 5;       % [Hz] make sure this is above the most high frequency mode that should be plotted in the diagram

counter = 0;
for i = 1:length(freq)
    if (abs(imag(freq{i}))/2/pi > min_freq) & (abs(imag(freq{i}))/2/pi < max_freq)
        counter = counter + 1;
        Modes.Freq(counter,:) = abs(imag(freq{i}))/2/pi;
        Modes.Damping(counter,:) = -100*real(freq{i})./abs(freq{i});
    end
end

%%
% CampbellGUI(GUIInputs)
farve = 'kbrgmckbrgmckbrgmckbrgmckbrgmckbrgmc';
Modes.NModes = size(Modes.Freq,1);
Config.color = farve(1:Modes.NModes);
Config.line = repmat({'-'},Modes.NModes,1);
Config.plot = ones(Modes.NModes,1);
Config.LineWidth = ones(Modes.NModes,1);
Config.Legend = repmat({'To be defined'},Modes.NModes,1);
Config.Permutation = repmat([1:Modes.NModes]',1,length(Modes.WS));
Config.SelectedMode= NaN;
Config.SelectedPoint.WSidx = NaN;
Config.SelectedPoint.Modeidx = NaN;

DataAnimode.Res = Res;
DataAnimode.Info = Info;
DataAnimode.Turbgeom = Turbgeom;
DataAnimode.Flow = Flow;

GUICampbell(Modes,STA,Config,DataAnimode)
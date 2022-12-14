% clear all; close all; clc;
% Script to generate LC for designing OptiTip

% See 0055-4135.V00 for guideline

%% Settings
run('OptiTip_Configuration.m');
% -- redirect some variables
GBXRatio   = OTC.GBXRatio;
Radius     = OTC.Radius;
RatedPower = OTC.RatedPower;

%% check that this part is to be executed
if(OTC.Steps(1)==0)
    fprintf('This step was disabled in configuration. Check OTC.Steps variable.\n');
    fprintf('Configuration defines the following steps to be executed:\n');
    for i=1:length(OTC.Steps)
        fprintf('\tStep %d: ',i);
        if(OTC.Steps(i)==0)
            fprintf('skip\n');
        else
            fprintf('execute\n');
        end
    end
    error('This step was disabled in configuration. Check OTC.Steps variable.');
end

%% Define envelop of LC (RPM and Pitch for each WS)
fprintf('Generating DLCs...\n');

WS.WS = WS.min:WS.step:WS.max;
if Ref.OptiTip.TSR(end) < GRPM.min*2*pi*Radius./(GBXRatio*60*WS.WS(1))
    min_ws_TSR = GRPM.min*2*pi*Radius./(GBXRatio*60*WS.WS(1));
    error('Maximum TSR in first guess is %0.3f, maximum TSR at WS %d is %0.3f, please include this TSR in first guess and try again.',Ref.OptiTip.TSR(end),WS.WS(1),ceil(min_ws_TSR*100)/100)
end

for i=1:length(WS.WS)
    LC.RPM.Min(i) = NaN; LC.RPM.Max(i) = NaN; LC.Pitch.Min(i) = NaN; LC.Pitch.Max(i) = NaN;
    if WS.WS(i)<=Part1.MaxWS
        LC.RPM.Min(i) = GRPM.min/GBXRatio;
        LC.RPM.Max(i) = GRPM.min/GBXRatio;
        RefPitch         = round(interp1(Ref.OptiTip.TSR,Ref.OptiTip.Pitch,GRPM.min*2*pi*Radius./(GBXRatio*60*WS.WS(i)))/Pitch.step)*Pitch.step;
        LC.Pitch.Min(i) = max(RefPitch-Pitch.Amp,Pitch.min);
        LC.Pitch.Max(i) = max(RefPitch+Pitch.Amp,Pitch.min);
        clear RefPitch;
    end
    if WS.WS(i)>=Part2.MinWS && WS.WS(i)<=Part2.MaxWS
        TmpMinRPM = 60*WS.WS(i)*OptiLambda.min/(2*pi*Radius);
        TmpMaxRPM = 60*WS.WS(i)*OptiLambda.max/(2*pi*Radius);
        LC.RPM.Min(i) = min(LC.RPM.Min(i),max(GRPM.min/GBXRatio,TmpMinRPM));
        LC.RPM.Max(i) = max(LC.RPM.Max(i),min(GRPM.max/GBXRatio,TmpMaxRPM));
        clear TmpMinRPM TmpMaxRPM;

        TmpRefPitch = round(interp1(Ref.OptiTip.TSR,Ref.OptiTip.Pitch,[OptiLambda.min:OptiLambda.Step:OptiLambda.max])/Pitch.step)*Pitch.step;
        LC.Pitch.Min(i) = min(LC.Pitch.Min(i),max(Pitch.min,min(TmpRefPitch)-Pitch.Amp));
        LC.Pitch.Max(i) = max(LC.Pitch.Max(i),max(TmpRefPitch)+Pitch.Amp);
        clear TmpRefPitch;
    end
    if WS.WS(i)>=Part3.MinWS
        LC.RPM.Min(i) = min(LC.RPM.Min(i),GRPM.max/GBXRatio);
        LC.RPM.Max(i) = GRPM.max/GBXRatio;
        TmpRefPitch         = round(interp1(Ref.OptiTip.TSR,Ref.OptiTip.Pitch,GRPM.max*2*pi*Radius./(GBXRatio*60*WS.WS(i)))/Pitch.step)*Pitch.step;
        LC.Pitch.Min(i) = min(LC.Pitch.Min(i),max(Pitch.min,TmpRefPitch-Pitch.Amp));
        LC.Pitch.Max(i) = max(LC.Pitch.Max(i),max(Pitch.min,TmpRefPitch+Pitch.Amp));
        clear TmpRefPitch;
    end
end

%% Apply optilambda step and roundings
for i=1:length(WS.WS)
    LC.RPM.Step(i) = round(OptiLambda.Step*60/(2*pi*Radius)*WS.WS(i)*100)/100; % Precision of 0.01 rpm
    LC.RPM.Min(i) = floor(LC.RPM.Min(i)/LC.RPM.Step(i))*LC.RPM.Step(i);
    LC.RPM.Max(i) = ceil(LC.RPM.Max(i)/LC.RPM.Step(i))*LC.RPM.Step(i);
    LC.Pitch.Min(i) = floor(LC.Pitch.Min(i)/Pitch.step)*Pitch.step;
    LC.Pitch.Max(i) = ceil(LC.Pitch.Max(i)/Pitch.step)*Pitch.step;
end

%% Plots of LC range
figure(1);
subplot(211); hold on;
plot(WS.WS,LC.RPM.Min)
plot(WS.WS,LC.RPM.Max)
ylabel('Rotor speed [rpm]')
subplot(212); hold on;
plot(WS.WS,LC.Pitch.Min)
plot(WS.WS,LC.Pitch.Max)
xlabel('Wind Speed [m/s]')
ylabel('Pitch [deg]')

% print(fullfile(pwd,'Step_1_selection.png'),'-dpng','-r300')
% saveas(gcf,fullfile(pwd,))

%% Defining LC
count = 1;
for i=1:length(WS.WS)

    TmpRPM = LC.RPM.Min(i):LC.RPM.Step(i):LC.RPM.Max(i);
    TmpPitch = LC.Pitch.Min(i):Pitch.step:LC.Pitch.Max(i);
    
    for j=1:length(TmpRPM)
        for k=1:length(TmpPitch)
            LC.LC.WS(count) = WS.WS(i);
            LC.LC.Pitch(count) = TmpPitch(k);
            LC.LC.RPM(count) = TmpRPM(j);
            LC.LC.t(count) = round(60/LC.LC.RPM(count)*100)/100;
            count = count+1;
        end
    end
end

disp(['Number of Load Cases: ',num2str(count-1)]);

%% Copy LC
fprintf('\tStoring LCs at: %s\n',[pwd, '\LC.txt']);
fid = fopen('LC.txt','w');
% fprintf(fid,'Run the following load cases. Remember:\n Make DRT rotation DOF OFF \n Use the Prep version which rounds the rotor speed after 2 decimals \n reduce number of sensors to minimum and add AoA sensors in the blade file (suggestion: h:\\2MW\\MK10B\\V100\\Investigations\\001_OptiTip\\Tables\\PARTS\\sensor_OptiTip.001) \n\n\n');

for i=1:length(LC.LC.WS)
    fprintf(fid,'LC_%05i \nCONST Freq -1 LF 1.0 \n%.2f 0 %.2f 0 Pitch0 9999 %.2f %.2f %.2f Time 0.01 %.2f 10 30 Vexp 0.15 slope 0 \n\n',i,LAC.rounddp(LC.LC.RPM(i),2),LC.LC.WS(i),LC.LC.Pitch(i),LC.LC.Pitch(i),LC.LC.Pitch(i),LC.LC.t(i));
end

fclose(fid);

% return;
fprintf('OK\n');


%% Prepare simulations part (VLLEB)
fprintf('Preparing simulation...\n');
% ---------------------------
% --- Set-up computation dirs
% ---------------------------
sim_dir = fullfile(pwd,OTC.Step_1.dir);
fprintf('\tSetting up directories:\n');
fprintf('\t\tCreating: %s\n',sim_dir);
mkdir(sim_dir)
fprintf('\tOK\n');
% ---------------------------
% --- Sensor file
% ---------------------------
sensor_file = fullfile(sim_dir,'sensor_OptiTip.001');
fprintf('\tGenerating sensor file:\n');
fprintf('\t\tOutput: %s\n',sensor_file);
fileID = fopen(sensor_file,'w');
fprintf(fileID,'OUTPUTSENSORS: %s generated by Opti-Tip LAC script\n',datestr(now, 'yyyy-mm-dd'));
fprintf(fileID,'- *\n');   
fprintf(fileID,'+ Vhub\n');
fprintf(fileID,'+ Pi2\n');
fprintf(fileID,'+ Omega\n');
fprintf(fileID,'+ Fthr\n');
fprintf(fileID,'+ Maero\n');
fprintf(fileID,'+ AoA2*\n');
fclose(fileID);
fprintf('\tOK\n');
% ---------------------------
% --- Initialize prep creation 
% ---------------------------
prep=LAC.vts.convert(prepTemplate, 'REFMODEL');
[folder, prepfile, postfix] = fileparts(prepTemplate);
% ---------------------------
% --- Read in BLD and add AoA sensors
% ---------------------------
fprintf('\tGenerating blade file\n');
if exist(prep.Files('BLD'), 'file')
    bld_read = prep.Files('BLD');
    [filepath,name,ext] = fileparts(prep.Files('BLD'));
    bld_file = fullfile(sim_dir, [name,ext]);
elseif exist(fullfile(prep.PartsFolder,'BLD',prep.Files('BLD')), 'file')
    bld_read = fullfile(prep.PartsFolder,'BLD',prep.Files('BLD'));
    bld_file = fullfile(sim_dir, prep.Files('BLD'));
else
    error('Was not able to localize BLD file.');
end
bld=LAC.vts.convert(bld_read, 'BLD');
% -- remove all out and insert AoA instead
for i=1:length(bld.SectionTable.Out)
    bld.SectionTable.Out{i} = '0 aoa';
end
fprintf('\t\tSaving: %s\n',bld_file)
bld.encode(bld_file);
fprintf('\tOK\n');
% ---------------------------
% --- Continue prep creation 
% ---------------------------
fprintf('\tGenerating prep file\n');
% --- ammend prep file
% - change DOFs
prep.BladeDOF1 = 1;
prep.BladeDOF2 = 0;
prep.BladeDOF3 = 1;
prep.BladeDOF4 = 0;
prep.BladeDOF5 = 1;
prep.BladeDOF6 = 0;
prep.DOF13 = 0;
prep.DOF14 = 1;
prep.DOF15 = 1;
prep.DOFDownwind1 = 0;
prep.DOFDownwind2 = 0;
prep.DOFDownwind3 = 0;
prep.DOFDownwind4 = 0;
prep.DOFLateral1 = 0;
prep.DOFLateral2 = 0;
prep.DOFLateral3 = 0;
prep.DOFLateral4 = 0;
% - change SENSOR
prep.Files('SEN') = sensor_file;
% - change BLD
prep.Files('BLD') = bld_file;
% - replace DLCs
lcObj         = LAC.codec.CodecTXT('LC.txt');
loadcases     = lcObj.getData;
prep.comments = sprintf('%s \n',loadcases{:});
% --- store prep file
prep_file =  fullfile(sim_dir,[prepfile,'_OTC',postfix]);
fprintf('\t\tSaving: %s\n',prep_file)
prep.encode(prep_file);
fprintf('\tOK\n');
% ---------------------------
% --- Create CtrlParamChanges
% ---------------------------
% fprintf('\tGenerating CtrlParamChanges file\n');
% if exist(fullfile(folder,'_CtrlParamChanges.txt'))==2
%     fprintf('\t\tCtrlParamChanges file exists\n');
%     fprintf('\t\tDisabling VTL\n');
%     fileID = fopen(fullfile(folder,'_CtrlParamChanges.txt'),'r');
%     CTRLfile={};
%     while ~feof(fileID)
%       CTRLfile{end+1,1} =fgetl(fileID);
%     end
%     % --- disable VTL 
%     CTRLfile{end+1,1} = 'Px_TL_Enable = 0;';
%     fclose(fileID);
%     fprintf('\t\tSaving: %s\n',fullfile(sim_dir,'_CtrlParamChanges.txt'))
%     fileID = fopen(fullfile(sim_dir,'_CtrlParamChanges.txt'),'w');
%     fprintf(fileID,'%s\n',CTRLfile{:});
%     fclose(fileID);
% else
%     fprintf('>>> _CtrlParamChanges.txt was not found. Make sure it is located next to your prep file! <<<\n');
%     error('_CtrlParamChanges.txt was not found');    
% end
% fprintf('\tOK\n');





clear all; fclose all; clc;
% INPUTS:
% 	simPath - path to existing power curve, must be prepped
% 	ct_max - an array of Ct values to target, this should include a range of values around the spciefied ct target. e.g. [0.85:0.01:0.70]
% 	outputfolder - a folder location for the outputs to be saved
%
% OUTPUTS:
% 	Plot of Ct surface with OTC values for constant Ct
%   Parameter study file with OTC control parameters for constant Ct
%
% VERSIONS:
% 	2022/07/13 - KESCO: V00
%
%%
%Inputs
% Path to baseline PC run (PC prep minimum required)
simPath = 'h:\ENVENTUS\Mk1a\Variants\F1A\Investigations\103_Ct_Modes\00_Baseline\';
% Ct Max values
ct_max = [0.73];
% Location for outputs to be saved
outputfolder = 'h:\ENVENTUS\Mk1a\Variants\F1A\Investigations\103_Ct_Modes\100_Tuning_Check\Script_Out\';
%%%% End User Input %%%%%%%%%
%%
% Check path to inputs exists
if exist([simPath 'PC\QuickPowerCurve\Rho1.225\'],'dir')
    simPath = [simPath 'PC\QuickPowerCurve\Rho1.225\'];
elseif exist([simPath 'PC\Normal\Rho1.225\'],'dir')
    simPath = [simPath 'PC\Normal\Rho1.225\'];
else
    error(['Cannot find simulation path in: ' simPath])
end
%
% Find CtrlInput
if exist([simPath 'INPUTS\CtrlInput.txt'],'file') %take Cp and Ct from outfile
    ctrlInput = [simPath 'INPUTS\CtrlInput.txt'];
else
    error(['Cannot find CtrlInput in: ' simPath '\INPUTS\'])
end
%
% Read CtrlInput and create Ct surface
fid = fopen(ctrlInput);
tline = fgetl(fid);
ii=0;zz=0;yy=0;
while ischar(tline)
    ii = ii+1;
    %
    if strcmp(tline,'CT-table')
        readCT = 1;
    end
    if isempty(tline)
        readCT = 0;
    end
    %
    if readCT
        zz = zz+1;
        temp = strsplit(tline)';
        if zz==1
            %skip
        elseif zz==2
            if strcmp(temp{2},'lambda\theta')
                Pi2Surf = str2double(temp(3:end));
            else
                Pi2Surf = str2double(temp(2:end));
            end
        else
            yy=yy+1;
            if isempty(temp{1})
                tsrSurf(yy,1) = str2double(temp(2));
                CtSurf(yy,:) = str2double(temp(3:end));
            else
                tsrSurf(yy,1) = str2double(temp(1));
                CtSurf(yy,:) = str2double(temp(2:end));
            end
        end
        C{zz}=tline;
    end
    tline = fgetl(fid);
end
fclose(fid);
%
% Get OTC Values
ParameterList = {...
    'Px_OTC_TableLambdaToPitchOptX01'
    'Px_OTC_TableLambdaToPitchOptX02'
    'Px_OTC_TableLambdaToPitchOptX03'
    'Px_OTC_TableLambdaToPitchOptX04'
    'Px_OTC_TableLambdaToPitchOptX05'
    'Px_OTC_TableLambdaToPitchOptX06'
    'Px_OTC_TableLambdaToPitchOptX07'
    'Px_OTC_TableLambdaToPitchOptX08'
    'Px_OTC_TableLambdaToPitchOptX09'
    'Px_OTC_TableLambdaToPitchOptX10'
    'Px_OTC_TableLambdaToPitchOptX11'
    'Px_OTC_TableLambdaToPitchOptX12'
    'Px_OTC_TableLambdaToPitchOptX13'
    'Px_OTC_TableLambdaToPitchOptX14'
    'Px_OTC_TableLambdaToPitchOptY01'
    'Px_OTC_TableLambdaToPitchOptY02'
    'Px_OTC_TableLambdaToPitchOptY03'
    'Px_OTC_TableLambdaToPitchOptY04'
    'Px_OTC_TableLambdaToPitchOptY05'
    'Px_OTC_TableLambdaToPitchOptY06'
    'Px_OTC_TableLambdaToPitchOptY07'
    'Px_OTC_TableLambdaToPitchOptY08'
    'Px_OTC_TableLambdaToPitchOptY09'
    'Px_OTC_TableLambdaToPitchOptY10'
    'Px_OTC_TableLambdaToPitchOptY11'
    'Px_OTC_TableLambdaToPitchOptY12'
    'Px_OTC_TableLambdaToPitchOptY13'
    'Px_OTC_TableLambdaToPitchOptY14'
    'Px_OTC_RotorRadius'
    };
PrdCtrlFile = dir([simPath 'INPUTS\ProdCtrl_*']);
if isempty(PrdCtrlFile)
    error(['Cannot find ProdCtrl csv file in: ' simPath 'INPUTS\'])
end
ParameterFile = fullfile(PrdCtrlFile.folder,PrdCtrlFile.name);
parameters = readParameterValues(ParameterFile,ParameterList);
otc_tsr=[];otc_pitch=[];
for kk = 1:length(ParameterList)-1
    if strcmp(ParameterList{kk}(end-2),'X')
        otc_tsr(end+1,1) = parameters.(ParameterList{kk});
    elseif strcmp(ParameterList{kk}(end-2),'Y')
        otc_pitch(end+1,1) = parameters.(ParameterList{kk});
    else
        error(['Check parameter name: ' ParameterList{kk}])
    end
end
%
% get sta values
[sens_data,~] = myStareadTL({'Vhfree';'Pi2';'Omega'},[simPath 'STA\'],'94',{'mean'});
radius = parameters.Px_OTC_RotorRadius;
ws = sens_data(1).mean';
rotspd_rpm = sens_data(3).mean';
pitch = sens_data(2).mean';
rotspd_rps =rotspd_rpm*2*pi/60;
tsr = rotspd_rps*radius./ws;
%
% Interpolation Matrices
ct_temp_sta = interp1(tsrSurf,CtSurf,tsr);
for ii = 1:length(pitch)
    ct_sta(ii) = interp1(Pi2Surf,ct_temp_sta(ii,:),pitch(ii));
end
ct_temp_otc = interp1(tsrSurf,CtSurf,otc_tsr);
for ii = 1:length(otc_pitch)
    ct_otc(ii) = interp1(Pi2Surf,ct_temp_otc(ii,:),otc_pitch(ii));
end
%
% find pitch angle for a reduction in Ct from OTC
for nn = 1:length(ct_max)
    for jj = 1:length(otc_pitch)
        thisCtNew(jj,nn) = min(ct_otc(jj),ct_max(nn));
        thisCtMap = ct_temp_otc(jj,:);
        pitch_offset(jj,nn) = max(otc_pitch(jj),interp1(thisCtMap([diff([0 ct_temp_otc(jj,:)])<0]),Pi2Surf([diff([0 ct_temp_otc(jj,:)])<0]),thisCtNew(jj,nn)));
    end
end
pitch_deltas = pitch_offset-otc_pitch;
%
% Plotting
figure
surf(repmat(tsrSurf,1,size(CtSurf,2)),repmat(Pi2Surf',size(CtSurf,1),1),CtSurf)
hold on
scatter3(tsr,pitch,ct_sta,'r')
scatter3(otc_tsr,otc_pitch,ct_otc,100,'g')
pp_count = length(ct_max);
for pp = 1:pp_count
    scatter3(otc_tsr,pitch_offset(:,pp),thisCtNew(:,pp),'y')
end
xlabel('TSR')
ylabel('Pitch Angle (°)')
zlabel('Ct')
colorbar
legend('Ct Surface','Mean operation Points from DLC 9.4','OTC Points','Offset OTC Points')
savefig([outputfolder '\CtPitchOffsets.fig'])
%
% Write output
fid = fopen( [outputfolder '\_ParameterStudy.txt'], 'wt' );
for mm = 1:14
    if mm<10
        fprintf(fid,['Par0%i->%s = %f' repmat(',%f',1,size(pitch_offset,2)-1) '\n'], mm, ParameterList{mm+14},pitch_offset(mm,:));
    else
        fprintf(fid,['Par%i->%s = %f' repmat(',%f',1,size(pitch_offset,2)-1) '\n'], mm, ParameterList{mm+14},pitch_offset(mm,:));
    end
end
fprintf(fid,['\n']);
fprintf(fid,['Study01->Par01~Par02~Par03~Par04~Par05~Par06~Par07~Par08~Par09~Par10~Par11~Par12~Par13~Par14']);
fclose(fid);





function [parameters] = readParameterValues(ParameterFile,ParameterList)
%% Finds the values of parameters given in ParameterList in the ParameterFile (CSV)
%
Param = LAC.vts.convert(ParameterFile,'AuxParameterFile');
for j = 1:length(ParameterList)
    [parameter, value, index] = getParamExact(Param, ParameterList(j));
    if isempty(value) == 1 || isempty(parameter)
        error('Parameter "%s" not found or has no value - fool!',ParameterList{j})
    end
    parameters.(parameter{1}) = value;
end
end

function sens = loadSensData(filelst, sensors, type)

sensor_index = zeros(1,length(sensors));

for i=1:length(filelst)
    
    filepath = strcat( strcat(filelst(i).folder, '\' ), filelst(i).name);
    data = LAC.vts.convert( filepath );
    
    for j=1:length(sensors)
        sensor_index(j) = find((strcmp(data.sensor, sensors{j}))==1);
        if max(strcmp(type,'mean'))
            sens(j).mean(i) = data.mean(sensor_index(j));
        end
        if max(strcmp(type,'max'))
            sens(j).max(i) = data.max(sensor_index(j));
        end
        if max(strcmp(type,'min'))
            sens(j).min(i) = data.min(sensor_index(j));
        end
        if max(strcmp(type,'std'))
            sens(j).std(i) = data.std(sensor_index(j));
        end
        if ~max([strcmp(type,'std');strcmp(type,'min');strcmp(type,'max');strcmp(type,'mean')])
            error('Not Valid Type')
        end
        
    end
    
end

end

function [sens_data,filelst] = myStareadTL(sensors,directory,file,type)

for ii=1:size(file,1)
    disp(['Reading Folder: ' directory])
    if contains(file(ii,:),'*')
        filelst_temp = dir( strcat(directory, file(ii,:), '.sta') );
    else
        filelst_temp = dir( strcat(directory, file(ii,:), '*.sta') );
    end
    if ii==1
        filelst = filelst_temp;
    else
        filelst = [filelst; filelst_temp];
    end
end
if isempty(filelst)
    % if no files found
    for ii = 1:length(sensors)
        sens_data(ii).data = NaN;
    end
    warning(['No load cases matching the variable boundingLCs found in ' directory]);
else
    sens_data = loadSensData( filelst, sensors ,type);
end

end

% Generate DLC to stress test Cold climate operation(CCO) feature
% based on LCT-915 
% V01 : 1st of July 2020
% Author: KAVAS
% Inputs 
    % Default VTS text file
    % Output file
    % FLC GS value - can be updated to read automatically.
% Output
    % Stress_DLC.txt file

clc;clear;close all


%% Inputs
prompt={'Input path to Baseline text file'};title='Step01:Input text file'; 
definput={'h:\FEATURE\ColdClimate\Simulation_Models\+++VTSModel+++\V150_HH105\002\00_Baseline\V150_LTq_5.60_IEC_HH105.0_VAS_STE_T966909.txt'};
userinput1=inputdlg(prompt,title,[1 150],definput);

inpath=userinput1{1};
%% reading text file
[~,flname,~]=fileparts(inpath);
raw=LAC.vts.convert(inpath,'REFMODEL');

if raw.WindSpeeds('Vin')<4    raw.WindSpeeds('Vin')=4; end;

%% output file
prompt={'Output path to StressDLC'};title='Step02:Output path'; 
outinput={'h:\FEATURE\ColdClimate\Simulation_Models\StressDLC\V150\'};
userinput2=inputdlg(prompt,title,[1 100],outinput);outpath=userinput2{1};

%% writing text file
fidout=fopen(fullfile(outpath,[flname,'_Stress_DLC.txt']),'wt');

%1. DLC11 to capture transition lambda optimal, to TL, to FL and vice-versa
LAC.scripts.ColdClimateOperations.StressDLC.DLC11(raw,fidout,10,1);
%2. DLC11 with low turbulence
LAC.scripts.ColdClimateOperations.StressDLC.DLC11(raw,fidout,10);
%3. DLC11
LAC.scripts.ColdClimateOperations.StressDLC.DLC11(raw,fidout);
%4. DLC12
LAC.scripts.ColdClimateOperations.StressDLC.DLC12(raw,fidout);
%5. DLC13
LAC.scripts.ColdClimateOperations.StressDLC.DLC13(raw,fidout);
%6. DLC13 with FLC GS tuning 
LAC.scripts.ColdClimateOperations.StressDLC.DLC13(raw,fidout,1);
%7. DLC14
LAC.scripts.ColdClimateOperations.StressDLC.DLC14(raw,fidout);
%8. DLC21 RPY
LAC.scripts.ColdClimateOperations.StressDLC.DLC21(raw,fidout,'RPY');
%9. DLC21 PSBB
LAC.scripts.ColdClimateOperations.StressDLC.DLC21(raw,fidout,'PSBB');
%10. DLC31 NTM
LAC.scripts.ColdClimateOperations.StressDLC.DLC31(raw,fidout,'NTM');
%10. DLC31 ETM
LAC.scripts.ColdClimateOperations.StressDLC.DLC31(raw,fidout,'ETM');
fclose('all');
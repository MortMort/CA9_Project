%% Running HAWC for 1p critical project
% Required inputs in the Dialogue box
% -VTS Text file
% -Interested in Parameter or Reference Study - 1/0(Reference)
% -HTC sensor End Txt - SysWrap inpvec  24  # PitchPosRefC
% Author - KAVAS - 11th of April 2018.
% HAWC2 Guideline - http://wiki.tsw.vestas.net/display/LACWIKI/Setting+up+HAWC2+model
% 1p Critical Tuning - 0071-6411; http://wiki.tsw.vestas.net/display/LACWIKI/Step+3+-+Tune+SSTD+Fixed+Phase+Offset

clear all;close all;
rootfol=[pwd '\'];

%% inputs
prompt={'VTS Txt file','Required HAWC2 Sensors','Reference Study','Sweep Study','HTC sensor End Txt'};title='Step01:User Inputs'; 
definput={'V120_2.00_IECS_HH92_INF_STE_60HZ_1P_0061_4920_858876_bc3bb1.txt','h:\FEATURE\1PCriticalOperation\Scripts\+HAWC\_Support\OutputSensorFile.txt','1','1','SysWrap inpvec  24  # PitchPosRefC'};
userinput=inputdlg(prompt,title,[1 70],definput);

txtfile=userinput{1};
sentxtfile=userinput{2};% 1 local/0 for cluster
runRef=str2double(userinput{3});
runSweep=str2double(userinput{4});
HTCsen_endtxt=userinput{5};

%% preparing the simulations
% Fat1 prep
LAC.HAWC2.VTSTempRun(rootfol,txtfile)

% Reading the parameter study
if runSweep [HWC]=LAC.HAWC2.Parametertxtreader(rootfol); end

%identify the controller files
[VTSCtrl]=LAC.HAWC2.VTSCtrlfiles(rootfol);

% checking the parameter in controller  file
if runSweep [HWC]=LAC.HAWC2.ParameterCheckinCSV(rootfol,VTSCtrl,HWC); end

% reading the required sensors
sensforHAWC2=LAC.HAWC2.HWCsens(sentxtfile);

%% Sweep runs Setting up.
if runSweep==1
    
    for i=1:length(HWC.Parameter_Values)
        mkdir([rootfol,'01_0',num2str(i-1,'%.2d')]);
        simulationpath=fullfile(rootfol,['01_0',num2str(i-1,'%.2d')]);
        copyfile(fullfile(rootfol,txtfile),simulationpath);
        sysCommandLine = ['prep002v05_033 -hawc2 -forcecontinue ' fullfile(simulationpath,txtfile),'< nul'];
        msg=(['01_0',num2str(i-1,'%.2d'),':  ','Text copied, HAWC2Prep on going...']);
        disp(msg);
        [prepStatus prepResults] = system(sysCommandLine);
        
        %% Modifying HTC file for required sensor
        LAC.HAWC2.HWCsensinHTC(simulationpath,txtfile,HTCsen_endtxt,sensforHAWC2);              
                
        %% Copying CSV Files from VTS runs
        disp('Updating csv files ...');
        LAC.HAWC2.CopyCSVfromVTStoHWC(rootfol,simulationpath,VTSCtrl);
        
        %% updating CSV file
        LAC.HAWC2.ParamterUpdateinCSV(simulationpath,HWC,i);
        
        %% updating twr Emod file
        LAC.HAWC2.HWCUpdateTwrStiffness(simulationpath,HWC,i);
        
        %% Run VTS
        copyfile([rootfol,'interface.txt'],fullfile(simulationpath,'INPUTS'));
        sysCommandLine = ['start vtsview_ms ', fullfile(simulationpath,'INPUTS','RUNHAWC2.bat')];
        disp(sysCommandLine);
        system(sysCommandLine);
    end
end

if runRef==1
    mkdir([rootfol,'Ref']);
    simulationpath=fullfile(rootfol,['Ref']);
    copyfile(fullfile(rootfol,txtfile),simulationpath);
    sysCommandLine = ['prep002v05_033 -hawc2 -forcecontinue ' fullfile(simulationpath,txtfile),'< nul'];
    msg=(['Ref',':  ','Text copied, HAWC2Prep on going...']);
    disp(msg);
    [prepStatus prepResults] = system(sysCommandLine);
    
    %% Modifying HTC file for required sensor
    LAC.HAWC2.HWCsensinHTC(simulationpath,txtfile,HTCsen_endtxt,sensforHAWC2);
    
    %% Copying CSV Files
    disp('Updating csv files ...');
    LAC.HAWC2.CopyCSVfromVTStoHWC(rootfol,simulationpath,VTSCtrl);    
        
    %% Run VTS
    copyfile([rootfol,'interface.txt'],fullfile(simulationpath,'INPUTS'));
    sysCommandLine = ['start vtsview_ms ', fullfile(simulationpath,'INPUTS','RUNHAWC2.bat')];
    disp(sysCommandLine);
    system(sysCommandLine);
end

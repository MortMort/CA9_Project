%% Standstill Stability Wrapper (main script)
% This wrapper creates relevant folders, set-up simulations and 
% process results for standstill stability evaluations. 
%
% Tips: 
% - Run script section by section. 
% - Documentation in LAC wiki.
% 
% Inputs:
% defineTurbineConfigurations - Define turbine configurations according to
%                               platform service scenarios or use default 
%                               definitions in a preliminary study.
% 
% ppOnly                      - Post-process only. Use this if simulations 
%                               have already run to skip the initializing 
%                               sections. (y/n).
% 
% finalStabMapOnly            - Only plots final stability maps at the 
%                               allowable wind speeds disregarding maps 
%                               at the swept wind speeds. (y/n).
% 
% forcereadSTA                - Read stafiles disregarding stapost.mat 
%                               availability in simulation folders.(y/n). 
% 
% runVstabAnalysis            - Executes and process VStab analysis. (y/n).
% 
% manuallyIdentifyModes       - Manually identify EV modes using Animode.
%                               If disabled a simple algorithm locates
%                               the modes accordingly. (y/n).
% 
% Date: Oct 2020 - PECJA

clc
clear
close all

%% Read turbine configurations (define before running)
turbine = defineTurbineConfigurations;
% turbine = LAC.scripts.StandstillStability.defineTurbineConfigurations;

%% Initialization flags
% time domain
ppOnly                  = false;  % (y/n) only post-process results 
finalStabMapOnly        = true;  % (y/n) only plot stabmaps@allowable wsp
forcereadSTA            = 0;     % (y/n) read sta-files regardless of stapost

% vstab
runVstabAnalysis        = false; % (y/n) run and process vstab analysis 
manuallyIdentifyModes   = false; % (y/n) manually identify modes


% checking toolbox hash (version control)
if ~ppOnly
    LAC.scripts.StandstillStability.misc.checkToolboxVersion;
end

if runVstabAnalysis
    VStabPath = 'W:\ToolsDevelopment\VStab\CURRENT\SOURCE';
    addpath(VStabPath);
end

%% Folder structure (default)
risk_curves = 'risk_curves';

ref = 'reference';
ref_loads = [ref '/loads_comp'];
ref_model = [ref '/model_data'];

vstab = 'vstab';
vstab_frq = [vstab '/freq_analysis'];
vstab_2d = [vstab '/2D_analysis'];

%% Initialization: Simulation folders, prepfiles, Quickstart_FAT1, parameters etc.
if ~ppOnly    
qs_string = ''; % initiate string for QuickStart
for t=1:length(turbine) % turbines / variants
    
    % creating simulation folders
    outfolder = ['./' turbine(t).name '/' turbine(t).hub_height];    
    
    if ~exist(outfolder,'dir')
        mkdir(outfolder,vstab_2d);
        mkdir(outfolder,vstab_frq);
        mkdir(outfolder,ref_loads);
        mkdir(outfolder,ref_model);
        mkdir(outfolder,risk_curves);
    end
    
    % writing clean prepfile (no LCs)
    [pathstr,filename,ext] = fileparts(turbine(t).prepfile);    
    prepfile_clean = fullfile(outfolder,[filename '_clean' ext]);
    fid_in = fopen(turbine(t).prepfile);
    fid_out = fopen(prepfile_clean,'w');

    line = fgets(fid_in);
    while ischar(line)
        if strfind(line,'SEN') % inserting reduced sensor-file
            sensor_file = 'SEN W:\ToolsDevelopment\FAT1\PartFiles\SEN\SSS_sensors.001';
            fprintf(fid_out,'%s\n',sensor_file);
        else                
            fprintf(fid_out,'%s',line);
        end

        if strfind(line,'LOAD CASES')
            break;
        end
        line = fgets(fid_in);
    end
    fclose(fid_in);
    fclose(fid_out);    
    
    for c=1:length(turbine(t).config) 
        % file levels
        sublevel = ['VTS/' turbine(t).config(c).case]; % VTS sublevel
        fullpath = [outfolder '/' sublevel];
       
        % service configurations
        config = turbine(t).config(c); 
        
        % appending prepfiles in string
        qs_string = [qs_string [fullpath '/VTS_SSS.txt'] blanks(1)]; 

        if ~exist(fullpath,'dir')
            mkdir(fullpath); % VTS simulation folder
        end

        % copying clean prepfile and writing load cases from service configurations   
        disp('Writing VTS SSS prepfile')
        copyfile(prepfile_clean,[fullpath '/VTS_SSS.txt'])
        
        LAC.scripts.StandstillStability.misc.LoadCaseWriter( ...
        [fullpath '/VTS_SSS.txt'],...
        config.idleflag, ...
        config.standstillpitch, ... 
        'windspeeds', config.wsps, ...
        'pitch_misalignment', config.pitch_misalignment, ...
        'azimuths', config.azim, ...
        'winddirs',config.wdir);
        disp('Done')
    end
end
    
% writing Quickstart_FAT1 for all configuations
disp('Writing Quickstart for FAT1.');
fid = fopen('Quickstart_FAT1.bat','w');
fprintf(fid,'%s',['FAT1 -priority -5 -loads -r 011100000000 -u -p' blanks(1) qs_string]);
fclose(fid);
disp('Setup done, execute Quickstart_FAT1.bat file.')
warning('Prep before continuing with the analysis. Press enter when finalized or Ctrl-c to stop.')
pause
end    
    
% Standstill Stability Analysis
for t=1:length(turbine) % turbines / variants 
    
    % working folders
    outfolder = ['./' turbine(t).name '/' turbine(t).hub_height];    
    fullpath = [outfolder '/VTS/' turbine(t).config(1).case];
    turbname = [turbine(t).name '_' turbine(t).hub_height];   
    
    f_frq = [outfolder '/' vstab_frq];
    f_2d = [outfolder '/' vstab_2d]; 
    f_risk = [outfolder '/' risk_curves];
    
    mkdir([f_frq '/INPUTS/']) % creating INPUTS folder
    standstillpitch = turbine(t).config(1).standstillpitch; % 1st case config
    
    % copy and back-up turbine master file
    copyfile([fullpath '/Loads/INPUTS/VTS_SSS.mas'],[f_frq '/INPUTS/VTS_SSS.mas.bak']); 
    masfn = [f_frq '/INPUTS/VTS_SSS.mas'];
    masfnBak = [f_frq '/INPUTS/VTS_SSS.mas.bak'];
             
    % removing noise equation from master file
    fid_in = fopen(masfnBak);
    fid_out = fopen(masfn,'W');
    line = fgets(fid_in);
    while ischar(line)
        if strfind(line,'Number of noise equations')
            while strfind(line,char(10))~=2 % read until newline
                line = fgets(fid_in);
                prevline = line; % insert previous line (newline)
            end
            fprintf(fid_out,'%s',prevline);
        else
            fprintf(fid_out,'%s',line);
        end
        line = fgets(fid_in);    
    end
 
    % read blade properties for VStab simulations
    bldFile = dir([fullpath '/Loads/PARTS/BLD/*']);
    bladeProps = LAC.vts.convert([fullpath '/Loads/PARTS/BLD/' bldFile(3).name],'BLD');
    
    % standstill profiles
    [~,filename,ext] = fileparts(bladeProps.ProfileData.STANDSTILL); 
    stProfi = [filename ext];
    
    if(isempty(stProfi)) % copy profile data from master file
        error('Could not locate standstill .PRO-file. Copy it to Vstab\Freq_Analysis\INPUTS\ manually and continue script execution.');
    end
    copyfile([fullpath '/Loads/INPUTS/' stProfi],[f_frq '/INPUTS/']);
    profiles = [f_frq '/INPUTS/' stProfi];
    
    % read weibull parameters for return period calculations
    wndFile = dir([fullpath '/Loads/PARTS/WND/*']);
    wndProps = LAC.vts.convert([fullpath '/Loads/PARTS/WND/' wndFile(3).name],'WND');
    
    % read V1 wind in prepfile
    fid = fopen(turbine(t).prepfile);
    line = fgets(fid);
    while ischar(line)
        if regexp(line,'[vV]1\s+\d')
            lineparts = strsplit_LMT(line);
            damping.wsp = str2double(lineparts(2));
            break
        else
            line = fgets(fid);
        end
    end
    fclose(fid); 
    
%% VStab Analysis (frequency domain)
    if runVstabAnalysis
        % damping analysis 
        disp('Running VStab.')    
        LAC.scripts.StandstillStability.freq_domain.VStab_BladeOnly(...
            damping,standstillpitch,masfn,profiles,turbname,f_2d)
        disp('Done running VStab.')

        LAC.scripts.StandstillStability.freq_domain.dampingData(...
            damping,bladeProps,turbname,f_2d)

        LAC.scripts.StandstillStability.freq_domain.dampingPlotting(...
        bladeProps,turbname,f_2d)

       % frequency analysis (campbell)
        disp('Running VStab.')    
        idleflag = 1;    
        freqFileIdle = LAC.scripts.StandstillStability.freq_domain.baselineFreq(...
            masfn,profiles,turbname,standstillpitch,idleflag,f_frq);

        idleflag = 0;
        freqFileLock = LAC.scripts.StandstillStability.freq_domain.baselineFreq(...
            masfn,profiles,turbname,standstillpitch,idleflag,f_frq);    
        disp('Done running VStab.')

    if manuallyIdentifyModes
        if(~exist('YawMode','var') || ~exist('TiltMode','var') || ~exist('ColMode','var'))
        msgbox({'Identify first three edgewise modes (yaw, tilt and collective (from: ', freqFileLock ,'Enter them in follwing dialog.'},'Animode Locked' )
        pause(4)

        % locked
        Animode
        disp('Press enter when done finding the lock modes')
        pause

        prompt={'Yaw mode','Tilt mode','Collective mode:'};
           name=['Animode: Identify first three edgewise modes (yaw, tilt and collective (from ' freqFileLock ')'] ;
           numlines=1;
           defaultanswer={'6','7','9'};
           answer=inputdlg(prompt,name,numlines,defaultanswer,'on');
        YawMode(1) = str2double(answer{1});
        TiltMode(1) = str2double(answer{2});
        ColMode(1) = str2double(answer{3});

        msgbox({'Identify first three edgewise modes (yaw, tilt and collective (from: ', freqFileIdle ,'Enter them in follwing dialog.'},'Animode Idle' )
        pause(4)

        % idling
        Animode
        disp('Press enter when done finding the idling modes')
        pause

        prompt={'Yaw mode','Tilt mode','Collective mode:'};
           name=['Animode: Identify first three edgewise modes (yaw, tilt and collective (from ' freqFileIdle ')'] ;
           numlines=1;
           defaultanswer={'5','6','8'};
           answer=inputdlg(prompt,name,numlines,defaultanswer,'on');
        YawMode(2) = str2double(answer{1});
        TiltMode(2) = str2double(answer{2});
        ColMode(2) = str2double(answer{3});
        else
        disp('YawMode, TiltMode and ColMode variables alread exist. To run Animode, clear at least one of these and rerun')    
        end
        else
        YawMode = [];
        TiltMode = [];
        ColMode = [];
    end
    LAC.scripts.StandstillStability.freq_domain.baselineCampbell(turbname,f_frq,YawMode,TiltMode,ColMode,manuallyIdentifyModes)
    end

%% VTS Analysis (time domain)
    % static moment
    bladeMassProps = bladeProps.computeMass;
    Smom1 = bladeMassProps.Smom1; % [kgm] Blade static moment
    p2pMoment = 2*9.81*Smom1/1000; % [kNm] Peak-to-peak gravity bending moment    
                 
    for c=1:length(turbine(t).config) % service configurations        
        % map wdir to yawerr
        wdir = turbine(t).config(c).wdir;
        if length(wdir)>1
            yawerr = [wdir(wdir>=180)-360 wdir(wdir<180)];
        else
            yawerr = wdir;
        end   
        turbine(t).config(c).yawerr = yawerr;
        
       % add wind parameters 
       turbine(t).config(c).k = wndProps.k;
       turbine(t).config(c).Vave = wndProps.Vav;
       turbine(t).config(c).TI = wndProps.Turbpar; 

       % config
       config = turbine(t).config(c);
       config.p2pMoment = p2pMoment; % add p2p moment

       % process STA files
       LAC.scripts.StandstillStability.misc.processSTA([turbname '_' config.case],...
            [outfolder '/VTS/' config.case '/Loads/'],f_risk,forcereadSTA);   

       % calculate risk factors and assemble loads matrix    
       LAC.scripts.StandstillStability.time_domain.calculateRiskFactors(config,turbname,f_risk);

        % stability maps @ swept wind speeds
        if ~finalStabMapOnly
            LAC.scripts.StandstillStability.time_domain.stabilityMap(config,f_risk,turbname);  
        end

        % calculate & plot risk curves, return periods
        LAC.scripts.StandstillStability.time_domain.returnPeriodCalc(config,...
            f_risk,turbname,config.k,config.Vave);

    end  
    [q_allowed] = LAC.scripts.StandstillStability.time_domain.plotRiskCurves(...
        turbine(t),f_risk,turbname);

    % compare EV loads to operational
    [pathstr,filename,ext] = fileparts(turbine(t).prepfile);
    LAC.scripts.StandstillStability.time_domain.loadComparison(turbine(t),outfolder,...
    turbname,bladeProps,[pathstr '/Loads/Postloads/BLD/BLDload.txt'],q_allowed,...
    risk_curves,ref_loads)     

    % stability maps @ allowable wind speeds
    LAC.scripts.StandstillStability.time_domain.stabilityMapFinal(turbine,turbname,...
    outfolder,p2pMoment,risk_curves,ref_loads);      
end


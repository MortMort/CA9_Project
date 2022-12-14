function frq = towerfrq(inputpath)
%TOWERFRQ - Calculate gravity correction on tower frequency from EIG-file
%Function to read VTS eig-file and correct the tower frequency for gravity
%influence. The function writes an outputfile and also calculates 1P margin
%and margin to minimum 3P rotor frequency.
%
% Syntax:  [frq] = towerfrq(inputpath)
%
% Inputs:
%   inputpath       - full pathstring of masterfile or root of simulation
%                     or path to INPUTS in VTS-folder.
%
% Outputs:
%   frq.eig         - frequency extracted from eig-file
%   frq.corr        - corrected frequency using gravity correcetion
%   frq.factor      - correction factor used for calculating corrected frequency
%   frq.rotor1P     - 1P frequency on rotor (based on csv)
%   frq.rotor3Pmin  - 3P minimum generator speed (based on csv)
%   
%   outputfile      - textfile written in the root of the simulation
%
% Method: 
%   criticalLoad = pi^2*E*I/(2*H)^2      
%   factor       = sqrt(1-F/Fc)
%
%   Mean tower properties are used along the height of the tower
%
% Example: 
%    [frq] = LAC.vts.towerfrq('h:\3MW\MK2A\V1053300.072\IEC1a.013\LOADS\')
%    [frq] = LAC.vts.towerfrq('h:\3MW\MK2A\V1053300.072\IEC1a.013\LOADS\INPUTS')
%    [frq] = LAC.vts.towerfrq('h:\3MW\MK2A\V1053300.072\IEC1a.013\LOADS\INPUTS\iec1a.mas')
%
% NOTE: This function can only be used as guidance.
%
% Other m-files required: LAC.vts.convert
% Subfunctions: none
% MAT-files required: none
%
% See also: LAC.vts.towerfrqtd

% Author: MAARD, Martin Brødsgaard
% February 2014; 
% V00 - Reviewed and validated by BHSUB, see DMS 0047-2305.
% V01 - Function can only be used for eig-flex 1.1 or lower.
version='V01';
%% Read inputs
% Read masterfile 
fid=fopen(inputpath);
if fid<0
    masfiles=dir(fullfile(fileparts(inputpath),'*.mas'));
    if ~isempty(masfiles)
        if length(masfiles)>1
            error('Several masterfiles found please use correct masterfile as input.')
        end
        inputpath=fullfile(fileparts(inputpath),masfiles.name);        
    else
        masfiles=dir(fullfile(fileparts(inputpath),'INPUTS','*.mas'));
        if ~isempty(masfiles)
            if length(masfiles)>1
                error('Several masterfiles found please point use correct masterfile as input.')
            end
            inputpath=fullfile(fileparts(inputpath),'INPUTS',masfiles.name);
        else        
            error([inputpath ' not found! Choose correct masterfile.'])
        end
    end
	fid=fopen(inputpath);
end
Mas=LAC.vts.convert(inputpath);
fclose(fid);

% Define inputpath
[inputpath, file]=fileparts(inputpath);
simpath=fileparts(inputpath);

% Read Frqfile
frqfile=fullfile(inputpath,[file '.frq']);
if ~exist(frqfile,'file')
    error([frqfile ' not found!'])
end

frq = LAC.vts.convert(frqfile);

% Read Eigfile
[~,eigfile] = fileparts(frq.LC{1});
eigfile     = fullfile(simpath,'EIG',[eigfile '.eig']);
i=1;
while ~exist(eigfile,'file')
    if i>length(frq.LC)
        error('No Eig-file found.')
    end
    [~,eigfile]= fileparts(frq.LC{i});
    eigfile    = fullfile(simpath,'EIG',[eigfile '.eig']);
    if ~exist(eigfile,'file')
        eigfile    = [eigfile '_Cleanup2Backup.old'];
    end
    i=i+1;    
end
Eig = LAC.vts.convert(eigfile);

if str2num(Eig.version)>1.3 % EIG v.1.3 still not gravity corrected
    errordlg(['Eig-file created by EIGFLEX5 Version ' Eig.version '! Not valid for gravity correction.'])
    error(['Eig-file created by EIGFLEX5 Version ' Eig.version '! Not valid for gravity correction.'])
end

towerFrqFromEig = Eig.frq(1);

% Read CSV
findCsv = fullfile(inputpath,'ProdCtrl_*.csv');
temp    = dir(findCsv);
csvfile = fullfile(inputpath,temp.name);
if isempty(temp)
    warning('Parameter file not found!')
    Parameters.empty=[];
else
    Parameters=LAC.vts.convert(csvfile);
end

%% Calculate correction factor
% Extract properties from masterfile
eModule        = Mas.twr.Emodule;
heighArray     = Mas.twr.ElHeight;
thickenssArray = Mas.twr.ElThickness;
outerDiaArray  = Mas.twr.ElDiameter;
innerDiaArray  = outerDiaArray-2*thickenssArray;

% Tower diameters (mean)
meanOuterDia   = mean(outerDiaArray);
meanInnerDia   = mean(innerDiaArray);

% Tower height (including foundation)
towerHeight    = max(heighArray);

% Nacelle, blade and hub mass
nacelleMass  = Mas.nac.NacelleMass;
bladeMass    = sum(diff(Mas.bld.Radius).*Mas.bld.m(2:end));
hubMass      = Mas.rot.HubMass;

% Total tower top mass
towerTopMass = 3*bladeMass+nacelleMass+hubMass;
% m=mas.twr.Density*pi*(D^2-d^2);

% Area moment of inertia on tower sections
I=pi/64 * (meanOuterDia^4-meanInnerDia^4);

% Critical buckling load (fixed-free)
criticalLoad = pi^2*eModule*I/(2*towerHeight)^2;
verticalLoad = towerTopMass*9.81;

corr=sqrt(1-verticalLoad/criticalLoad);
frq_corr=corr*towerFrqFromEig;

%% Check of frequency
% Simple calculation of tower frequency, shall only be used at check of
% calculation!!
K=3*eModule*I/towerHeight^3;

frq_est=sqrt(K/towerTopMass)/(2*pi);

if ~any(strcmp(fieldnames(Parameters),'values'))
    ratedRpm   = 0;
    minimumStaticRpm = 0;
    rotorFrequency1P=0;
    rotorFrequency3Pmin = 0;
else
    %% Check of 1P margin
    ratedRpm = Parameters.values(not(cellfun('isempty', strfind(Parameters.parameters,'Px_LDO_GenSpdSetpoint'))));
    if isempty(ratedRpm)
        ratedRpm = Parameters.values(not(cellfun('isempty', strfind(Parameters.parameters,'Px_LDO_GenSpdSetpoint'))));
    end
    if isempty(ratedRpm)
        ratedRpm = Parameters.values(not(cellfun('isempty', strfind(Parameters.parameters,'Px_NomTorqRPM'))));
    end
    gearratio = Mas.drv.Ngear;

    rotorFrequency1P=ratedRpm/gearratio/60;

    %% Check of 3P margin
    minimumStaticRpm = Parameters.values(not(cellfun('isempty', strfind(Parameters.parameters,'Px_GenStarMinConnectSpd'))));
    if isempty(minimumStaticRpm)
        minimumStaticRpm = Parameters.values(not(cellfun('isempty', strfind(Parameters.parameters,'Px_LSO_GenStarMinStaticSpd'))));
    end
    if isempty(minimumStaticRpm)
        minimumStaticRpm = Parameters.values(not(cellfun('isempty', strfind(Parameters.parameters,'Px_SC_GenStarMinStaticSpd'))));
    end


    rotorFrequency3Pmin = 3*minimumStaticRpm/gearratio/60;
end
frq = struct('eig',towerFrqFromEig,'corr',frq_corr,'factor',corr,'rotor1P',rotorFrequency1P,'rotor3Pmin',rotorFrequency3Pmin);

%Calculate actual ratio between 3P low and tower (adjusted) frequency.
frq.ratio_rotor3Pmin_divided_by_eig_corr = rotorFrequency3Pmin/frq_corr;

%% Write output
outfile='TowerFrequency.txt';
fout=fopen(fullfile(simpath,outfile),'w+');
fprintf(fout,'Generated by the Matlab function ''twrFrqEig()''\n');
fprintf(fout,'Created on %s by %s\n\n',date,getenv('USERNAME'));

fprintf(fout,'1ST TOWER MODE FREQUENCIES\n');
fprintf(fout,'---------------------------------\n');
fprintf(fout,'From EIG-file:          %4.3f Hz\n',frq.eig);
fprintf(fout,'Gravity corrected:      %4.3f Hz\n',frq.corr);
fprintf(fout,'Correction factor:      %4.2f \n\n',frq.factor);
if abs(1-towerFrqFromEig/frq_est)>0.05
    warning(['Frequency estimation made from 1 DOF system (i.e. sqrt(K/M)/(2*pi)=' sprintf('%.3f', frq_est) ') differs with %s%% from eig frequency=' sprintf('%.3f',towerFrqFromEig) ', correction factor may not be valid!'],num2str(abs(1-towerFrqFromEig/frq_est)*100));
    fprintf(fout,'NB - Uncertainty of %s%% or more on correction factor, consider if corrected frequency is valid!\n\n',num2str(abs(1-towerFrqFromEig/frq_est)*100));
end

fprintf(fout,'DISTANCE TO 1P AND 3P\n');
fprintf(fout,'---------------------------------\n');
fprintf(fout,'1P Rotor Frequency:     %4.3f Hz (%4.0f RPM)\n',frq.rotor1P,ratedRpm);
fprintf(fout,'Ratio Twr frq/1P:       %4.2f \n\n',frq.corr./frq.rotor1P);
fprintf(fout,'3P Min Rotor Frequency: %4.3f Hz (%4.0f*3 RPM)\n',frq.rotor3Pmin(1),minimumStaticRpm);
fprintf(fout,'Ratio Twr frq/3P min:   %4.2f \n\n',frq.corr./frq.rotor3Pmin(1));

fprintf(fout,'INPUT FILES\n');
fprintf(fout,'---------------------------------\n');
fprintf(fout,'Simulation folder: %s\n',simpath);
fprintf(fout,'Master file:       %s\n',inputpath);
fprintf(fout,'EIG file:          %s\n',eigfile);
fprintf(fout,'CSV file:          %s\n',csvfile);
fprintf(fout,'---------------------------------\n\n');
fprintf(fout,'NOTE: \nThe corrected tower frequency is calculated assuming uniform thickness along tower height.\n\n');
fprintf(fout,'%s: Reviewed and validated by BHSUB, see DMS 0047-2305\n',version);
fclose(fout);

fprintf('Output saved in %s.\n',fullfile(simpath,outfile));
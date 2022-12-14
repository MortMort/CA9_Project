function VSCoutToVTSclm(Outfile, extendbins)
% Generates a VTS climate file based on a VSC *.out file
%
%Note: You will need to create a local copy of  ProbBin.m from the toolbox
%in order to run this function. 
%
% Input:    VSC output file
%           'extendbins': optional input, default set to 0 (false)
%                         -only to be used when calculating extended
%                         cut-out wind speed
%                         -if set to 1 (true), the DETwind and ETM values
%                         are extrapolated to the higher wind speed bins
%                         above cut-out
% Output:   '*.clm' in the same folder as the VSC outfile and with the same
%           name as the VSC file.
%           'WTG_No_*_WSM.mat' in the same folder as the VSC outfile,only if
%           there is WSM implemented on the WTG used in NTM_Fat
%
% The script takes the worst loaded turbine in the VSC *.out file based
% on a user input. Based on the component of interest, the effective
% turbulence is choosen:
% 1. Fatigue Blade loads   	(m = 10)
%    Take the effective turbulence from the turbine with the highest blade loads.
% 2. Fatigue Nacelle loads	(m = 8)
%    Take the effective turbulence from the turbine with the highest nacelle loads.
% 3. Fatigue Tower loads   	(m = 4)
%    Take the effective turbulence from the turbine with the highest tower loads.
% 4. All components 		(m = 10)
%    Take the effective turbulence from the turbine with the worst loaded component.
%
% Turbulence levels not available in the VSC *.out file have been
% extrapolated, based on a linear fit to the turbulence standard deviation.
% This is based on the assumption also used in IEC61400-1, ed.3. The
% linear fit have been limited to not have a negative slope to avoid
% unrealistic levels in the extrapolated turbulence values.
%
% A minimums limit for the turbulence have been set.
%       DETwind  NTM_Fat  NTM_Ext  ETM
% Iref  0.08     0.08     0.08     0.08
%
% Example command:
% VSCoutToVTSclm('W:\SOURCE\TLtoolbox\dummy\101111dbart Wainfleet .out')
%
% DMS: 0028-7612
%
% V01   ALKJA   2012-02-03
% V01.1 WISOR   2012-06-19  Added WSM output
% V02	ALKJA	2012-08-24  Updated to reflect SVN and added information to the *.clm filename

%%
% Minimum Iref values
%          DETwind   NTM_Fat   NTM_Ext   ETM     V50
MinIref = [0.08      0.08      0.08      0.08    0.05];

%%
%Defaults 'extendbins' to zero if user does not provide explicit input
%otherwise. 
if nargin == 1
    extendbins = 0;
end

%% Test files
% --- VSC.Classec tub file
% Outfile = 'W:\user\alkja\MatLab\VSCToClima\SangWang Tub_120217_123812.out';
% --- VSC.Classic i15 file
% Outfile = 'W:\user\alkja\MatLab\VSCToClima\SangWang i15_120217_123703.out';
% --- VSC.Classic IEC turb file
% Outfile = 'W:\user\alkja\MatLab\VSCToClima\SangWang Tub_120217_124326_IECturb.out';
% Outfile = 'W:\user\alkja\MatLab\VSCToClima\V100 1.8MW LaPM test_120116_093405_i15.out';
% --- VSC.Classic Raw data file
% Outfile = 'W:\user\alkja\MatLab\VSCToClima\VSC.net Test Lincoln_120215_025203.out';
% --- VSC.net Raw data file
%Outfile = 'v:\3MW\V90.3000\Mk5\PP\Investigations\177\BlueTrail\Blue Trail_120607_095624.out';

%% Whöler in VSC eff turbulence
mwholer = [4 8 10 3.3 5.7 8.7];

%% Read VSC-Out file and store in C
VSCOut.Outfile = Outfile;
[VSCOut.PATHSTR,VSCOut.NAME,EXT] = fileparts(VSCOut.Outfile);
fid = fopen(VSCOut.Outfile,'r');
C = textscan(fid,'%s','delimiter','\r');
C1 = char(C{1});
fclose(fid);
fid = fopen(VSCOut.Outfile,'r');
for i = 1:12
    VSCOut.VSCTopInfo{i} = fgets(fid);
end
fclose(fid);


%% Get Project Name
key = 'Project Name:';
pos = find(strncmpi(key,C{1},length(key)) == 1);
VSCOut.ProjectName = strtrim(C{1}{pos}(length(key)+1:end));

%% Test the version of outfile (VSC.Classic or VSC.net)
key = 'DLL load files used in farm:';
pos = find(strncmpi(key,C{1},length(key)) == 1);
if isempty(pos)
    VSCOut.VSCnet = true;
    
    key = 'Version: ';
    pos = find(strncmpi(key,C{1},length(key)) == 1);
    LineData = textscan(C{1}{pos(1)},'%s %s %s');
    CalculationDate = datenum(LineData{3}{1},'yyyymmdd');
    NewOutPutFormatDate = datenum('20151208','yyyymmdd');
    if (CalculationDate > NewOutPutFormatDate)
        VSCOut.VSCnetVersion = 2;
    else
        VSCOut.VSCnetVersion = 1;
    end
    
    key = 'MrTwrTop_Twr';
    pos = find(strncmpi(key,C{1},length(key)) == 1);
    VSCOut.extralinesaddedMrTT = 0;
    if length(pos) > 0 % Then Mr is available
        VSCOut.extralinesaddedMrTT = 1;
    end
    
    key = 'MrTwrBot_Twr';
    pos = find(strncmpi(key,C{1},length(key)) == 1);
    VSCOut.extralinesaddedMrTB = 4;
    if length(pos) > 0 % Then Mr is available
        VSCOut.extralinesaddedMrTB = 5;
    end
    
else
    VSCOut.VSCnet = false;
end

%% Read site variable
% air density, V50, Ve50, V50Turb
clc;
disp('--- VSCoutToVTSclm.m ------------------------------------------');
disp(' ')
disp('- Reading general Site data...')
VSCOut = ReadSiteVar(VSCOut,C);

%% Read Turbine Label and turbulence of worst fatigue loaded turbine depending on input
% This is for NTM_Fat...
disp(' ')
disp('- Reading effective turbulence for fatigue load calculation...')
VSCOut = ReadNTMFat(VSCOut,C);

%% Read Turbine Label and turbulence of worst ambient turbulence
% This is for DETwind and NTM_Ext
disp(' ')
disp('- Reading ambient turbulence for extreme load calculation...')
disp('  (If large park, then this takes some minutes)')
VSCOut = ReadAmbTurb(VSCOut,C);

%% Read Turbine Label and turbulence of worst extreme turbulence
% This is for 'ETM'...
disp(' ')
disp('- Reading extreme turbulence for extreme load calculation...')
VSCOut = ReadETMTurb(VSCOut,C);


%% store turbilence for VTS climate file
DeltaWindSpeed = 2; % 2 m/s bin
VSCOut.WindSpeed = 2:DeltaWindSpeed:38; % Wind speeds 2 m/s - 38 m/s 
VSCOut.VTSOut(1,:) = VSCOut.WindSpeed - DeltaWindSpeed/2; % start wind speed
VSCOut.VTSOut(2,:) = VSCOut.WindSpeed + DeltaWindSpeed/2; % end wind speed

% --- Store the turbulence levels from VSC out file (4 m/s - 24 m/s)
% find index for 
% index = find((strcmp(VSCOut.FatWLTLabel,VSCOut.AmbWTGLabel)) == 1);
for i = 1:11
    % Ambient turbulence
    TImin = NTM(MinIref(1),2*i+2);
    if VSCOut.MaxAmbTI90(i) > 0.0001
        VSCOut.VTSOut(3,i+1) = max(TImin,VSCOut.MaxAmbTI90(i));  % sum(( VSCOut.MeanAmbTurb(i,:) + 1.28 * VSCOut.StdAmbTurb(i,:) ) .* VSCOut.Prob)/sum(VSCOut.Prob);
    else
        VSCOut.VTSOut(3,i+1) = 0;
    end
    
    % NTM fatigue
    TImin = NTM(MinIref(2),2*i+2);
    Index = find(VSCOut.TIefftWholer == mwholer);
    if VSCOut.EffTurb(i,Index) > 0.0001
        VSCOut.VTSOut(4,i+1) = max(TImin,VSCOut.EffTurb(i,Index)); %max(VSCOut.EffTurb(i,Index),VSCOut.MaxAmbTI90(i)); % m = VSCOut.TIefftWholer
    else
        VSCOut.VTSOut(4,i+1) = 0;
    end
    
    % NTM extreme
    TImin = NTM(MinIref(3),2*i+2);
    if VSCOut.NTMext(i) > 0.0001
        VSCOut.VTSOut(5,i+1) = max(TImin,VSCOut.NTMext(i));      % As above
    else
        VSCOut.VTSOut(5,i+1) = 0;
    end
    
    % ETM
    TImin = ETM(MinIref(4),2*i+2,VSCOut.MeanW,2);
    if VSCOut.MaxETM(i) > 0.0001
        VSCOut.VTSOut(6,i+1) = max(TImin,VSCOut.MaxETM(i));
    else
        VSCOut.VTSOut(6,i+1) = 0;
    end
    % Wind speed prob
    % VSCOut.VTSOut(7,i+1) = sum(VSCOut.AmbProbWS{index}(i,:))/sum(VSCOut.AmbProb{index});
end

% Fill all other probability with 100%
% VSCOut.VTSOut(7,[1 13:end]) = 1;

% --- extrapolate turbulence in cells with turbulence under 0.0001 and wind
% speeds below 4 m/s and above 24 m/s.
for i = 1:4
    % minimum turbulence limit
    if i ~= 4
        TImin = NTM(MinIref(i),VSCOut.WindSpeed);
    else
        TImin = ETM(MinIref(i),VSCOut.WindSpeed,VSCOut.MeanW,2);
    end
    
    % turbulence standard deviation
    Sigma = VSCOut.VTSOut(i+2,:) .* VSCOut.WindSpeed;
    
    % find turbulence std not to extrapolate
    Exp = find(Sigma > 0.001);
    
    % fit to the lowest/highest 5 values
    LowFit = Exp(1:5);
    HighFit = Exp(end-4:end);
    
    % low wind extrapolation based lowest 5 points
    p = polyfit(VSCOut.WindSpeed(LowFit),Sigma(LowFit),1);
    if p(1) < 0.0, p(1) = 0.0; end
    VSCOut.VTSOut(i+2,1:Exp(1)-1) = max(...
        polyval(p,VSCOut.WindSpeed(1:Exp(1)-1)) ./ VSCOut.WindSpeed(1:Exp(1)-1),...
        TImin(1:Exp(1)-1));
    
    % high wind extrapolation based highest 5 points
    p = polyfit(VSCOut.WindSpeed(HighFit),Sigma(HighFit),1);
    if p(1) < 0.0 
        % if negative slope, then 'sigma' is set to the mean of the fit for
        % the higher wind speeds
        p(2) = mean(Sigma(HighFit));
        p(1) = 0.0; 
    end
    VSCOut.VTSOut(i+2,Exp(end)+1:end) = max(...
        polyval(p,VSCOut.WindSpeed(Exp(end)+1:end))  ./ VSCOut.WindSpeed(Exp(end)+1:end),...
        TImin(Exp(end)+1:end));
    
    
    clear Sigma
end

for i = 1:4
    if (i == 4) | (i == 1) && extendbins==0
        VSCOut.VTSOut(i+2,[1 13:end]) = 0;
    elseif i == 2
        % set NTM_Fat > 24 m/s to ambient turbulence
        VSCOut.VTSOut(i+2,[13:end]) = VSCOut.VTSOut(i+2+1,[13:end]);
    end
end

% Add V50Turb
VSCOut.VTSOut(2,end) = max(round(VSCOut.V50+3),VSCOut.VTSOut(2,end));
IndexV50 = find(VSCOut.VTSOut(2,:)>VSCOut.V50);
VSCOut.VTSOut(4:5,IndexV50) = max(MinIref(5),VSCOut.V50Turb);

% --- Hardcoded data in Prep002v05.exe
PrepV50 = [50 42.5 37.5 30; 1 2 3 4];
pos=find(PrepV50(1,:) - VSCOut.V50 >= 0);
if isempty(pos)
    VSCOut.PrepI = 1;
else
    VSCOut.PrepI = PrepV50(2,pos(end));
end

%% Print file
PrintFile(VSCOut)

end

function Rho = CalcAirDensity(T,h)
% formulat : http://en.wikipedia.org/wiki/Density_of_air
p0 = 101325;    % pa
T0 = 288.15;    % K
g = 9.80665;    % m/s^2
L = 0.0065;     % K/m
R = 8.31447;    % J/(mol K)
M = 0.0289644;  % kg/mol 

% Mean density
Temp = 273.15 + T;
p = p0 * ( 1 - ((L*h)/T0))^( (g*M)/(R*L) );
Rho = (p*M) / (R*Temp);
end

function Turb = NTM(Iref,Vhub)
Turb = Iref * ( 0.75 * Vhub + 5.6 ) ./ Vhub;
end

function Turb = ETM(Iref,Vhub,MeanW,c)
Turb = c*Iref*(0.072*((MeanW/c) + 3)*((Vhub/c) - 4) + 10) ./ Vhub;
end

%% Read Turbine Label and turbulence of worst extreme turbulence
% This is for 'ETM'...
function VSCOut = ReadETMTurb(VSCOut,C)

if VSCOut.VSCnet 
    key = 'WTG Label   	Fatigue load  ';
else
    key = 'WTG No. Fatigue load  Extreme Vhub';
end
pos = find(strncmpi(key,C{1},length(key)) == 1);
NoTurbine = 0; i = 1;
Line = C{1}{pos+i};
while ~strcmp(Line,'');
    %StrTemp = textscan(Line,'%10c %s %*200c');
    if VSCOut.VSCnet 
        StrTemp = textscan(Line,'%10c %s %*200c');
    else
        StrTemp = textscan(Line,'%8c %s %*200c');
    end
    if strcmpi(StrTemp{2},'fail') | strcmpi(StrTemp{2},'ok');
        NoTurbine = NoTurbine + 1;
        VSCOut.ETMWTGLabel{NoTurbine} = deblank(StrTemp{1});
        ETMWTGLabel{NoTurbine} = i;
    end
    i = i+1;
    Line = C{1}{pos+i};
end

% get full turbine label
key = 'Turbine distances';
pos = find(strncmpi(key,C{1},length(key)) == 1);
for Turbine = 1:NoTurbine
    Line = C{1}{pos+2+ETMWTGLabel{Turbine}};
    StrTemp = textscan(Line,'%12c %*200c');
    if strncmpi(StrTemp{1},VSCOut.ETMWTGLabel{Turbine},length(VSCOut.ETMWTGLabel{Turbine}));
        VSCOut.ETMWTGLabel{Turbine} = deblank(StrTemp{1});
    end
end

for Turbine = 1:NoTurbine
    
    % -- find the line number/index for the worst fatigue loaded turbine
    key = 'Wind Turbine number:';
    pos = find(strncmpi(key,C{1},length(key)) == 1);
    AllTurbines = size(pos,1);
    for i=1:AllTurbines
        Index = strfind(C{1}{pos(i)},'Label:');
        StrTemp = strtrim(C{1}{pos(i)}(Index+7:end));
        if strcmp(VSCOut.ETMWTGLabel{Turbine},StrTemp)
            WTGLine = pos(i);
            WTGIndex = i;
            break;
        elseif i == AllTurbines
            disp(['Turbine label: ' VSCOut.ETMWTGLabel{Turbine} ' - No found']);
        end
    end
    
    % -- extract wind distribution values
    UpdateOfLayoutClimate = false;
    key = 'Wind Distribution:';
    pos = find(strncmpi(key,C{1},length(key)) == 1);
    if isempty(pos) % update to outfile layout
        key = 'Climatic conditions:';
        pos = find(strncmpi(key,C{1},length(key)) == 1);
        UpdateOfLayoutClimate = true;
    end
    pos = pos(WTGIndex);
    if VSCOut.VSCnet 
        if UpdateOfLayoutClimate, skipLines = 3; else skipLines = 5; end 
    else skipLines = 4; end
    
    lineToRead = pos+skipLines;
    % - Vhub avg.
    StrTemp = textscan(C{1}{lineToRead+1},'%s') ;
    MeanW = str2double(StrTemp{1}{4});

    % -- extract the extreme turbulence level
    % if do no exist then calc ETM based on climate data
    key = 'Overall extreme annual wake turbulence and load';
    pos = find(strncmpi(key,C{1},length(key)) == 1);
    if isempty(pos)
        % Iref = mean ambient turb at 15 m/s
        if VSCOut.NoSAmbTurb{1} == 1
            % Iref = mean(VSCOut.MeanAmbTurb{1}(6:7,1)); % - Old Implementation
            Iref = mean(VSCOut.SiteTI90{Turbine}(6:7))/((0.75*15+5.6)/15); % calulation Iref based on 90% quintile of the ambient turbulence
        elseif VSCOut.NoSAmbTurb{1} == VSCOut.NoSWindParameters
            % I14 = sum(( VSCOut.MeanAmbTurb{1}(6,:)) .* VSCOut.Prob)/sum(VSCOut.Prob); % - Old Implementation
            % I16 = sum(( VSCOut.MeanAmbTurb{1}(7,:)) .* VSCOut.Prob)/sum(VSCOut.Prob); % - Old Implementation 
            % Iref = mean([I14 I16]);                                                   % - Old Implementation
            Iref = mean(VSCOut.SiteTI90{Turbine}(6:7))/((0.75*15+5.6)/15); % calulation Iref based on 90% quintile of the ambient turbulence
        end
        c = 2;
        for i = 1:11
            Vhub = (2+2*i);
            ETMTurb(i) = ETM(Iref,Vhub,VSCOut.MeanW,c);
        end
    else
        pos = pos(WTGIndex);
        skipLines = 1;
        lineToRead = pos+skipLines;
        % I14 = sum(( VSCOut.MeanAmbTurb{1}(6,:)) .* VSCOut.Prob)/sum(VSCOut.Prob); % - Old Implementation
        % I16 = sum(( VSCOut.MeanAmbTurb{1}(7,:)) .* VSCOut.Prob)/sum(VSCOut.Prob); % - Old Implementation
        % Iref = mean([I14 I16]);                                                   % - Old Implementation   
        
        Iref = mean(VSCOut.SiteTI90{Turbine}(6:7))/((0.75*15+5.6)/15); % calulation Iref based on 90% quintile of the ambient turbulence
        for i = 1:11
            Vhub = (2+2*i);
            StrTemp = textscan(C{1}{lineToRead+i},'%s') ;
            ETMTurb(i) = str2num(StrTemp{1}{3}) * (ETM(Iref,Vhub,MeanW,2)/ETM(Iref,Vhub,MeanW,1.7));
        end
    end

    
    for WindSpeed = 1:11
        if ETMTurb(WindSpeed) == 0
            VSCOut.MaxETM(WindSpeed) = 0.0;
            VSCOut.MaxETMLabel{WindSpeed} = '-';
        else
            if Turbine == 1
                VSCOut.MaxETM(WindSpeed) = ETMTurb(WindSpeed);
                VSCOut.MaxETMLabel{WindSpeed} = VSCOut.ETMWTGLabel{Turbine};
            else
                if ETMTurb(WindSpeed) > VSCOut.MaxETM(WindSpeed)
                    VSCOut.MaxETM(WindSpeed) = ETMTurb(WindSpeed);
                    VSCOut.MaxETMLabel{WindSpeed} = VSCOut.ETMWTGLabel{Turbine};
                end
            end
        end
    end
    
end;

end

%% Read Turbine Label and turbulence of worst ambient turbulence
% This is for DETwind and NTM_Ext
function VSCOut = ReadAmbTurb(VSCOut,C)

if VSCOut.VSCnet 
    key = 'WTG Label   	Fatigue load  ';
else
    key = 'WTG No. Fatigue load  Extreme Vhub';
end
pos = find(strncmpi(key,C{1},length(key)) == 1);
NoTurbine = 0; i = 1;
Line = C{1}{pos+i};
while ~strcmp(Line,'');
    %StrTemp = textscan(Line,'%8c %s %*200c');
    if VSCOut.VSCnet 
        StrTemp = textscan(Line,'%10c %s %*200c');
    else
        StrTemp = textscan(Line,'%8c %s %*200c');
    end
    if strcmpi(StrTemp{2},'fail') | strcmpi(StrTemp{2},'ok');
        NoTurbine = NoTurbine + 1;
        VSCOut.AmbWTGLabel{NoTurbine} = deblank(StrTemp{1});
        AmbWTGLabel{NoTurbine} = i;
    end
    i = i+1;
    Line = C{1}{pos+i};
end

% get full turbine label
key = 'Turbine distances';
pos = find(strncmpi(key,C{1},length(key)) == 1);
for Turbine = 1:NoTurbine
    Line = C{1}{pos+2+AmbWTGLabel{Turbine}};
    StrTemp = textscan(Line,'%12c %*200c');
    if strncmpi(StrTemp{1},VSCOut.AmbWTGLabel{Turbine},length(VSCOut.AmbWTGLabel{Turbine}));
        VSCOut.AmbWTGLabel{Turbine} = deblank(StrTemp{1});
    end
end

for Turbine = 1:NoTurbine
    
    % -- find the line number/index for the worst fatigue loaded turbine
    key = 'Wind Turbine number:';
    pos = find(strncmpi(key,C{1},length(key)) == 1);
    AllTurbines = size(pos,1);
    for i=1:AllTurbines
        Index = strfind(C{1}{pos(i)},'Label:');
        StrTemp = strtrim(C{1}{pos(i)}(Index+7:end));
        if strcmp(VSCOut.AmbWTGLabel{Turbine},StrTemp)
            WTGLine = pos(i);
            WTGIndex = i;
            break;
        elseif i == AllTurbines
            disp(['Turbine label: ' VSCOut.AmbWTGLabel{Turbine} ' - No found']);
        end
    end
    
    % -- extract the mean ambient turbulence
    key = 'Distribution of Mean Ambient';
    pos = find(strncmpi(key,C{1},length(key)) == 1);
    pos = pos(WTGIndex);
    if VSCOut.VSCnet, skipLines = 2; else skipLines = 1; end
    lineToRead = pos+skipLines;
    for i = 1:11
        StrTemp = textscan(C{1}{lineToRead+i},'%s');
        if (size(StrTemp{1},1)==15 || size(StrTemp{1},1)==39), startline = 4; else startline = 3; end
        for j = startline:size(StrTemp{1},1)
            VSCOut.MeanAmbTurb{Turbine}(i,j-(startline-1)) = str2num(StrTemp{1}{j});
        end
    end
    VSCOut.NoSAmbTurb{Turbine} = size(VSCOut.MeanAmbTurb{Turbine},2);
    
    % -- extract the std of the ambient turbulence
    key = 'Distribution of Std. Dev. of Ambient';
    pos = find(strncmpi(key,C{1},length(key)) == 1);
    pos = pos(WTGIndex);
    if VSCOut.VSCnet, skipLines = 2; else skipLines = 1; end
    lineToRead = pos+skipLines;
    for i = 1:11
        StrTemp = textscan(C{1}{lineToRead+i},'%s') ;
        if (size(StrTemp{1},1)==15 || size(StrTemp{1},1)==39), startline = 4; else startline = 3; end
        for j = startline:size(StrTemp{1},1)
            VSCOut.StdAmbTurb{Turbine}(i,j-(startline-1)) = str2num(StrTemp{1}{j});
        end
    end
    
    key = 'Directional Turbulence Intensities m = 1';
    pos = find(strncmpi(key,C{1},length(key)) == 1);
    WohlerM1IsAvailable = false;
    if length(pos) > 2
        if pos(2)-pos(1) < 20
            WohlerM1IsAvailable = true;
        end
    end
    VSCOut.EffTIm1Read = false;
    if length(pos) > NoTurbine
        if WohlerM1IsAvailable
            % read wohler m=1
            VSCOut.EffTIm1Read = true;
            pos = pos(2*WTGIndex);
            if VSCOut.VSCnet, skipLines = 1; else skipLines = 1; end
            lineToRead = pos+skipLines;
            for i = 1:11
                StrTemp = textscan(C{1}{lineToRead+i},'%s') ;
                VSCOut.EffTIm1{Turbine}(i) = str2num(StrTemp{1}{2});
            end
        else
            % read wohler m=4
            VSCOut.EffTIm1Read = true;
            key = 'Effective Turbulence Intensities in Wind Farm';
            pos = find(strncmpi(key,C{1},length(key)) == 1);
            pos = pos(WTGIndex);
            if VSCOut.VSCnet, skipLines = 2; else skipLines = 1; end
            lineToRead = pos+skipLines;
            for i = 1:11
                StrTemp = textscan(C{1}{lineToRead+i},'%s') ;
                VSCOut.EffTIm1{Turbine}(i) = str2num(StrTemp{1}{2});
            end
        end;
    end
    
    % -- extract wind distribution values
    UpdateOfLayoutClimate = false;
    key = 'Wind Distribution:';
    pos = find(strncmpi(key,C{1},length(key)) == 1);
    if isempty(pos) % update to outfile layout
        key = 'Climatic conditions:';
        pos = find(strncmpi(key,C{1},length(key)) == 1);
        UpdateOfLayoutClimate = true;
    end
    pos = pos(WTGIndex);
    if VSCOut.VSCnet 
        if UpdateOfLayoutClimate, skipLines = 3; else skipLines = 5; end 
    else skipLines = 4; end

    lineToRead = pos+skipLines;
    % - Probability
    StrTemp = textscan(C{1}{lineToRead},'%s') ;
    for j = 4:size(StrTemp{1},1)
        VSCOut.AmbProb{Turbine}(j-3) = str2double(StrTemp{1}{j}); 
    end
    % - Mean wind
    StrTemp = textscan(C{1}{lineToRead+1},'%s') ;
    for j = 5:size(StrTemp{1},1)
        VSCOut.MeanWindDir{Turbine}(j-4) = str2double(StrTemp{1}{j}); 
    end
    % - WeibullA
    StrTemp = textscan(C{1}{lineToRead+2},'%s') ;
    for j = 5:size(StrTemp{1},1)
        VSCOut.WeibullADir{Turbine}(j-4) = str2double(StrTemp{1}{j}); 
    end
    % - Weibullk
    StrTemp = textscan(C{1}{lineToRead+3},'%s') ;
    for j = 5:size(StrTemp{1},1)
        VSCOut.WeibullkDir{Turbine}(j-4) = str2double(StrTemp{1}{j}); 
    end
    % calculate wind speed probability based on weibull parameter
    for i = 1:11
        for dir = 1:length(VSCOut.MeanWindDir{Turbine})
            v = 2 + i*2;
            VSCOut.WeibullProbWSandDir(i,dir) = WeibullBinProbability(v, 2, VSCOut.WeibullADir{Turbine}(dir), VSCOut.WeibullkDir{Turbine}(dir)) * VSCOut.AmbProb{Turbine}(dir);
        end
    end
    
    % -- Extract the Wind Sector Management parameters, if applicable 
    key = 'Wind sector management  :';
    pos = find(strncmpi(key,C{1},length(key)) == 1);
    pos = pos(WTGIndex);
    WSMtest1 = pos + 2;
    WSMtest2 = pos + 3;
    VSCOut.WSMAvilable(Turbine) = false;
    if VSCOut.VSCnet
        if (isempty(C{1}{WSMtest1})==0) && (isempty(C{1}{WSMtest2})==0)
            if C{1}{WSMtest2}
                lineToRead = WSMtest1;
                kk=1;
                for i=1:4
                    if ~isempty(C{1}{lineToRead+i})
                        StrTemp = textscan(C{1}{lineToRead+i},'%s'); 
                        if size(StrTemp{1},1) == 3 | size(StrTemp{1},1) == 4
                            for j = 1:3%size(StrTemp{1},1)
                                VSCOut.WSMTurb{Turbine}(kk,j) = str2num(StrTemp{1}{j});
                                VSCOut.WSMAvilable(Turbine) = true;
                            end
                            kk=kk+1;
                        end
                    end
                end
            end
        end
    end
  
    % reduce wind destribution according to WSM
    if VSCOut.WSMAvilable(Turbine)
        for j = 1:size(VSCOut.WSMTurb{Turbine},1)
            bin_spacing = 360/size(VSCOut.AmbProb{Turbine},2);
            bin_center = 0:bin_spacing:359;
            n_bin = 360/bin_spacing;
            
            WSM_start =VSCOut.WSMTurb{Turbine}(j,1);
            if WSM_start > bin_center(end)+bin_spacing/2; WSM_start = WSM_start -360; end;
            WSM_end   =VSCOut.WSMTurb{Turbine}(j,2);
            if WSM_end > bin_center(end)+bin_spacing/2; WSM_end = WSM_end -360; end;
            
            AllTheWayAround = false;
            if (WSM_start == WSM_end) | (WSM_start == 0 & WSM_end == 360)
               AllTheWayAround = true;
            end
            
            WSM_WS    =VSCOut.WSMTurb{Turbine}(j,3);
            
            [min_val, index_start] = min(abs(bin_center-WSM_start));
            [min_val, index_end] = min(abs(bin_center-WSM_end));
            if index_end < index_start
                index = [index_start:n_bin 1:index_end];
            elseif AllTheWayAround
                index = 1:n_bin;
            else
                index = index_start:index_end;
            end
            
            firstFind = true;
            for i = 1:11
                WS_start = 1 + i*2;
                WS_end = 3 + i*2;
                if j == 1
                    %VSCOut.AmbProbWS{Turbine}(i,:) = VSCOut.AmbProb{Turbine};
                    VSCOut.AmbProbWS{Turbine}(i,:) = VSCOut.WeibullProbWSandDir(i,:);
                end
                
                if WS_end > WSM_WS
                    if firstFind
                        WSM_probWS = ((WS_end - WSM_WS) / 2);
                        firstFind = false;
                    else
                        WSM_probWS = 1;
                    end
                    for jj = index
                        if jj == index_start
                            WSM_probdir = 1-((bin_center(jj)+bin_spacing/2)-WSM_start) / bin_spacing;
                        elseif jj == index_end
                            WSM_probdir = 1-(WSM_end - (bin_center(jj)-bin_spacing/2)) / bin_spacing;
                        else
                            WSM_probdir = 0;
                        end
                        if WSM_probdir == 1
                            WSM_probdirTot = WSM_probdir;
                        else
                            WSM_probdirTot = WSM_probdir * WSM_probWS;
                        end
                        if AllTheWayAround, WSM_probdir = 0; end;
                        
                        VSCOut.AmbProbWS{Turbine}(i,jj) = VSCOut.AmbProbWS{Turbine}(i,jj) * WSM_probdirTot;
                    end
                end
            end
        end
    else
        for i = 1:11
            %VSCOut.AmbProbWS{Turbine}(i,:) = VSCOut.AmbProb{Turbine};
            VSCOut.AmbProbWS{Turbine}(i,:) = VSCOut.WeibullProbWSandDir(i,:);
        end
    end

    
%     % --- calculation the 90% quintile of the ambient turbulence on site (Bin
%     % calculations) - ALKJA
%     BinDelta = 0.0001;
%     CenterBin = BinDelta/2:BinDelta:1;
%     % loop of wind speeds
%     for j = 1:11
%         if VSCOut.NoSAmbTurb{Turbine} == 1
%             % IEC file
%             SiteTurb90{Turbine}(j) = VSCOut.MeanAmbTurb{Turbine}(j,1);
%         elseif VSCOut.StdAmbTurb{Turbine}(j) == 0
%             SiteTurb90{Turbine}(j) = sum(VSCOut.MeanAmbTurb{Turbine}(j,:) .* VSCOut.AmbProb{Turbine})/sum(VSCOut.AmbProb{Turbine});
%         else
%             % loop of sectors
%             for i = 1:VSCOut.NoSAmbTurb{Turbine}
%                 sectorprob = ProbBin(CenterBin,VSCOut.MeanAmbTurb{Turbine}(j,i),VSCOut.StdAmbTurb{Turbine}(j,i),0,'logn').*VSCOut.AmbProb{Turbine}(i)/sum(VSCOut.AmbProb{Turbine});
%                 if i == 1
%                     SumSectorprob = sectorprob;
%                 else
%                     SumSectorprob = SumSectorprob + sectorprob;
%                 end
%                 clear sectorprob
%             end
%             Pos = find(cumsum(SumSectorprob)> 0.90);
%             SiteTurb90{Turbine}(j) = CenterBin(Pos(1));
%             clear Pos SumSectorprob
%         end
%     end
    
    % --- calculation the 90% quintile of the ambient turbulence on site (LT) - Based on one prob per direction 
    %for i = 1:11
    %    Mean_a(i) = sum(VSCOut.MeanAmbTurb{Turbine}(i,:) .* (VSCOut.AmbProb{Turbine}/sum(VSCOut.AmbProb{Turbine})));
    %    Std_a(i)  = sqrt( sum( (VSCOut.AmbProb{Turbine}/sum(VSCOut.AmbProb{Turbine})) .* (VSCOut.MeanAmbTurb{Turbine}(i,:).^2 + VSCOut.StdAmbTurb{Turbine}(i,:).^2) ) - Mean_a(i)^2);
    %    SiteTI90{Turbine}(i) = Mean_a(i) + 1.28*Std_a(i);
    %end
    % --- calculation the 90% quintile of the ambient turbulence on site (LT) - Based on one prob per direction per wind speed
    for i = 1:11
        Mean_a(i) = sum(VSCOut.MeanAmbTurb{Turbine}(i,:) .* (VSCOut.AmbProbWS{Turbine}(i,:)/sum(VSCOut.AmbProbWS{Turbine}(i,:))));
        Std_a(i)  = sqrt( sum( (VSCOut.AmbProbWS{Turbine}(i,:)/sum(VSCOut.AmbProbWS{Turbine}(i,:))) .* (VSCOut.MeanAmbTurb{Turbine}(i,:).^2 + VSCOut.StdAmbTurb{Turbine}(i,:).^2) ) - Mean_a(i)^2);
        VSCOut.SiteTI90{Turbine}(i) = Mean_a(i) + 1.28*Std_a(i);
    end
    
    for WindSpeed = 1:11
        if Turbine == 1
            % Save ambinet turbulence
            VSCOut.MaxAmbTI90(WindSpeed) = VSCOut.SiteTI90{Turbine}(WindSpeed);
            VSCOut.MaxAmbTI90Label{WindSpeed} = VSCOut.AmbWTGLabel{Turbine};
            % save NTM_Ext (if EffTIm=1 exist use this else background turb)
            if VSCOut.EffTIm1Read
                VSCOut.NTMext(WindSpeed) = VSCOut.EffTIm1{Turbine}(WindSpeed);
                VSCOut.NTMextLabel{WindSpeed} = VSCOut.AmbWTGLabel{Turbine};
            else
                VSCOut.NTMext(WindSpeed) = VSCOut.SiteTI90{Turbine}(WindSpeed);
                VSCOut.NTMextLabel{WindSpeed} = VSCOut.AmbWTGLabel{Turbine};
            end                
        else
            % Save ambinet turbulence
            if VSCOut.SiteTI90{Turbine}(WindSpeed) > VSCOut.MaxAmbTI90(WindSpeed)
                VSCOut.MaxAmbTI90(WindSpeed) = VSCOut.SiteTI90{Turbine}(WindSpeed);
                VSCOut.MaxAmbTI90Label{WindSpeed} = VSCOut.AmbWTGLabel{Turbine}; 
            end
            % save NTM_Ext (if EffTIm=1 exist use this else background turb)
            if VSCOut.EffTIm1Read
                if VSCOut.EffTIm1{Turbine}(WindSpeed) > VSCOut.NTMext(WindSpeed)
                    VSCOut.NTMext(WindSpeed) = VSCOut.EffTIm1{Turbine}(WindSpeed);
                    VSCOut.NTMextLabel{WindSpeed} = VSCOut.AmbWTGLabel{Turbine};
                end                
            else
                if VSCOut.SiteTI90{Turbine}(WindSpeed) > VSCOut.NTMext(WindSpeed)
                    VSCOut.NTMext(WindSpeed) = VSCOut.SiteTI90{Turbine}(WindSpeed);
                    VSCOut.NTMextLabel{WindSpeed} = VSCOut.AmbWTGLabel{Turbine};
                end
            end
        end
    end
        
end;

end

%% Read Turbine Label and turbulence of worst fatigue loaded turbine depending on input
% This is for NTM_Fat...
function VSCOut = ReadNTMFat(VSCOut,C)
% User input
disp('Choose component to generate climate input to:');
disp('(based on the worst loaded turbine on the specific component)');
disp(' ')
disp('A : Fatigue Blade loads   (m = 10)');
disp('B : Fatigue Nacelle loads (m =  8)');
disp('C : Fatigue Tower loads   (m =  4)');
disp('D : Fatigue Tower Bottom loads   (m =  8)');
disp('E : All components (Worst loaded turbine on fatigue)');
disp('F : A specific turbine in the park');
disp(' ')
default = false;
Component = input('Select letter above (default = E) : ','s');
if isempty(Component)
    Component = 'E'; 
    default = true;
end;

result = strfind('abcdef',lower(Component));
if ~default
    while isempty(result)
       Component = input('Error in input. Please select letter above (a, b, c, d, e, or f) : ','s'); 
       result = strfind('abcdef',lower(Component));
    end
end

% Read data from Worst case relative loads
switch lower(Component)
    case 'a'
        VSCOut.FileNameExtemsion = '_m=10';

        key = '*** RELATIVE LOADS [%] ***';
        pos = find(strncmpi(key,C{1},length(key)) == 1);
        skipLines = 3;
        lineToRead = pos(1) + skipLines;
        MaxRelLoad = 0;
        for i = 1:4
            if VSCOut.VSCnet
                [RelLoad{i,1}] = textscan(C{1}{lineToRead},'%*s %*s %*s %*s %*s %f %10c %[^#]');
            else
                [RelLoad{i,1}] = textscan(C{1}{lineToRead},'%*s %*s %*s %f %10c %[^#]');
            end
            if RelLoad{i}{1} > MaxRelLoad
                MaxRelLoad = RelLoad{i}{1};
                Index = i;
            end
            lineToRead = lineToRead + 1;
        end
        VSCOut.FatWLTLabel = deblank(RelLoad{Index}{2});
        VSCOut.TIefftWholer = 10;
        VSCOut.FatTopText = 'Worst fatigue blade loads';
    case 'b'
        VSCOut.FileNameExtemsion = '_m=8';
        
        key = '*** RELATIVE LOADS [%] ***';
        pos = find(strncmpi(key,C{1},length(key)) == 1);
        lineToRead = pos(1) + 9;
        MaxRelLoad = 0;
        if VSCOut.VSCnet
            lines = [14 15 19 20 21 29 30 31 32];
            for i = 1:9;
                lineToRead = pos(1) + lines(i);
                [RelLoad{i,1}] = textscan(C{1}{lineToRead},'%*s %f %10c %f %10c %[^#]');
                [RelMax In] = max([RelLoad{i}{1} RelLoad{i}{3}]);
                if RelLoad{i}{In+(In-1)} > MaxRelLoad
                    MaxRelLoad = RelLoad{i}{In+(In-1)};
                    IndexComponent = i;
                    IndexWholer = In+(In-1)+1;
                end
            end
        else
            for i = 1:9
                [RelLoad{i,1}] = textscan(C{1}{lineToRead},'%*28c %f %10c %f %10c %[^#]');
                [RelMax In] = max([RelLoad{i}{1} RelLoad{i}{3}]);
                if RelLoad{i}{In+(In-1)} > MaxRelLoad
                    MaxRelLoad = RelLoad{i}{In+(In-1)};
                    IndexComponent = i;
                    IndexWholer = In+(In-1)+1;
                end
                lineToRead = lineToRead + 1;
            end
        end
        VSCOut.FatWLTLabel = deblank(RelLoad{IndexComponent}{IndexWholer});
        VSCOut.TIefftWholer = 8;
        VSCOut.FatTopText = 'Worst fatigue nacelle loads';
    case 'c'
        VSCOut.FileNameExtemsion = '_m=4';
        
        key = '*** RELATIVE LOADS [%] ***';
        pos = find(strncmpi(key,C{1},length(key)) == 1);
        if VSCOut.VSCnet, skipLines = 38 + VSCOut.extralinesaddedMrTT; else skipLines = 28; end
        lineToRead = pos(1) + skipLines;
        if VSCOut.VSCnet
            [RelLoad{1}] = textscan(C{1}{lineToRead},'%*s %f %10c %[^#]');            
        else
            [RelLoad{1}] = textscan(C{1}{lineToRead},'%*s %*s %*s %*s %f %10c %[^#]');
        end
        VSCOut.FatWLTLabel = deblank(RelLoad{1}{2});
        VSCOut.TIefftWholer = 4;
        VSCOut.FatTopText = 'Worst fatigue tower loads';
    case 'd'
        VSCOut.FileNameExtemsion = '_TWR_m=8';
        
        key = '*** RELATIVE LOADS [%] ***';
        pos = find(strncmpi(key,C{1},length(key)) == 1);
        if VSCOut.VSCnet, skipLines = 38 + VSCOut.extralinesaddedMrTT + VSCOut.extralinesaddedMrTB; else skipLines = 28; end
        lineToRead = pos(1) + skipLines;
        if VSCOut.VSCnet
            [RelLoad{1}] = textscan(C{1}{lineToRead},'%*s %f %10c %f %10c');            
        else
            [RelLoad{1}] = textscan(C{1}{lineToRead},'%*s %*s %*s %*s %f %10c %[^#]');
        end
        VSCOut.FatWLTLabel = deblank(RelLoad{1}{4});
        VSCOut.TIefftWholer = 8;
        VSCOut.FatTopText = 'Worst fatigue tower loads';
    case 'e'
        VSCOut.FileNameExtemsion = '_WorstCase';
        
        key = 'Effective turbulence intensities for the highest loaded turbines - ';
        pos = find(strncmpi(key,C{1},length(key)) == 1);
        if (VSCOut.VSCnet) 
            if VSCOut.VSCnetVersion == 1, skipLines = 2; else skipLines = 1; end 
        else skipLines = 1; end
        lineToRead = pos + skipLines;
        Dummy = textscan(C{1}{lineToRead},'%*s WTG No. %10c WTG No. %10c WTG No. %10c WTG No. %10c');
        if isempty(Dummy{1}) % 1.5.6 Updated 
            Dummy = textscan(C{1}{lineToRead},'%*s %10c %10c  %10c  %10c');
        end
        VSCOut.FatWLTLabel = strtrim(Dummy{1});
        VSCOut.TIefftWholer = 10;
        VSCOut.FatTopText = 'Worst fatigue loaded turbine';
    case 'f'
        disp(' ');
        disp('Turbine labels:')
        % list the turbine labels
        if VSCOut.VSCnet 
            key = 'WTG Label   	Fatigue load  ';
        else
            key = 'WTG No. Fatigue load  Extreme Vhub';
        end
        pos = find(strncmpi(key,C{1},length(key)) == 1);
        NoTurbine = 0; i = 1;
        Line = C{1}{pos+i};
        while ~strcmp(Line,'');
            %StrTemp = textscan(Line,'%8c %s %*200c');
            if VSCOut.VSCnet 
                StrTemp = textscan(Line,'%10c %s %*200c');
            else
                StrTemp = textscan(Line,'%8c %s %*200c');
            end
            if strcmpi(StrTemp{2},'fail') | strcmpi(StrTemp{2},'ok');
                NoTurbine = NoTurbine + 1;
                FatWTGLabel{NoTurbine} = deblank(StrTemp{1});
            end
            i = i+1;
            Line = C{1}{pos+i};
        end
        for i=1:NoTurbine
            fprintf(' %12s ',[FatWTGLabel{i}]);
            if mod(i,5) == 0
                fprintf('\n');
            end
        end
        disp(' ');
        WTGID = input('Please enter the WTG Label of the turbine you want to analyze: ','s');
        VSCOut.FileNameExtemsion = ['_WTG', WTGID];
        
        VSCOut.FatWLTLabel = WTGID;
        VSCOut.TIefftWholer = 10;
        VSCOut.FatTopText = ['WTG Label',WTGID];

end

%% Read VSC output for worst loaded turbine
% -- find the line number/index for the worst fatigue loaded turbine
key = 'Wind Turbine number:';
pos = find(strncmpi(key,C{1},length(key)) == 1);
NoTurbines = size(pos,1);
for i=1:NoTurbines
    Index = strfind(C{1}{pos(i)},'Label:');
    StrTemp = strtrim(C{1}{pos(i)}(Index+7:end));
    if strcmp(VSCOut.FatWLTLabel,StrTemp)
        WTGLine = pos(i);
        WTGIndex = i;
        break;
    elseif i == NoTurbines
        disp(['Turbine label: ' VSCOut.WLTLabel ' - No found']);
    end
end

% -- extract the effective turbulence at different whöler values
% Effective Turbulence Intensities in Wind Farm
% Vhub  m = 4.0   m = 8.0   m = 10.0  m = 3.3   m = 5.7   m = 8.7

key = 'Effective Turbulence Intensities in Wind Farm';
pos = find(strncmpi(key,C{1},length(key)) == 1);
pos = pos(WTGIndex);
if VSCOut.VSCnet, skipLines = 2; else skipLines = 1; end
lineToRead = pos+skipLines;
for i = 1:11
    StrTemp = textscan(C{1}{lineToRead+i},'%s') ;
    for j = 2:size(StrTemp{1},1)
        VSCOut.EffTurb(i,j-1) = str2num(StrTemp{1}{j});
    end
end

% -- extract wind distribution values
UpdateOfLayoutClimate = false;
key = 'Wind Distribution:';
pos = find(strncmpi(key,C{1},length(key)) == 1);
if isempty(pos) % update to outfile layout
    key = 'Climatic conditions:';
    pos = find(strncmpi(key,C{1},length(key)) == 1);
    UpdateOfLayoutClimate = true;
end
pos = pos(WTGIndex);
if VSCOut.VSCnet 
    if UpdateOfLayoutClimate, skipLines = 3; else skipLines = 5; end 
else skipLines = 4; end

lineToRead = pos+skipLines;
% - Probability
StrTemp = textscan(C{1}{lineToRead},'%s') ;
for j = 4:size(StrTemp{1},1)
    VSCOut.Prob(j-3) = str2double(StrTemp{1}{j}); end
VSCOut.NoSWindParameters = size(VSCOut.Prob,2);
% - Vhub avg.
StrTemp = textscan(C{1}{lineToRead+1},'%s') ;
VSCOut.MeanW = str2double(StrTemp{1}{4});
for j = 5:size(StrTemp{1},1)
    VSCOut.SecMeanW(j-4) = str2double(StrTemp{1}{j}); end
% - Weibull k
StrTemp = textscan(C{1}{lineToRead+3},'%s') ;
VSCOut.Weibk = str2double(StrTemp{1}{4});
for j = 5:size(StrTemp{1},1)
    VSCOut.SecWeibk(j-4) = str2double(StrTemp{1}{j}); end
% - Inflow
StrTemp = textscan(C{1}{lineToRead+4},'%s') ;
for j = 3:size(StrTemp{1},1)
    VSCOut.Inflow(j-2) = str2double(StrTemp{1}{j}); end
% - Wind Shear
StrTemp = textscan(C{1}{lineToRead+5},'%s') ;
for j = 4:size(StrTemp{1},1)
    VSCOut.WindShear(j-3) = str2double(StrTemp{1}{j}); end



end

%% Read site variable
% air density, V50, Ve50, V50Turb
function VSCOut = ReadSiteVar(VSCOut,C)

% -- Mean hub height
key = 'Summary of climatic conditions';
pos = find(strncmpi(key,C{1},length(key)) == 1);
StrTemp = textscan(C{1}{pos+4},'%*s %*s %*s %f');
VSCOut.HubHeightAvg = StrTemp{1};


% -- air density
key = 'Height above sea level';
pos = find(strncmpi(key,C{1},length(key)) == 1);
StrTemp = textscan(C{1}{pos},'%*s %*s %*s %*s %*s %f %*s %f');
VSCOut.SiteHeightAvg = mean([StrTemp{1} StrTemp{2}]);
VSCOut.SiteHeightMin = min([StrTemp{1} StrTemp{2}]);

key = 'Average annual ambient temperature';
pos = find(strncmpi(key,C{1},length(key)) == 1);
StrTemp = textscan(C{1}{pos},'%*s %*s %*s %*s %*s %*s %f');
VSCOut.TempAvg = StrTemp{1};
StrTemp = textscan(C{1}{pos+1},'%*s %*s %*s %*s %*s %*s %f');
VSCOut.TempMin = StrTemp{1};

if VSCOut.VSCnet
    key = 'Air density - average';
    pos = find(strncmpi(key,C{1},length(key)) == 1);
    StrTemp = textscan(C{1}{pos},'%*s %*s %*s %*s %*s %f');
    VSCOut.RhoAvg = StrTemp{1};
    StrTemp = textscan(C{1}{pos+1},'%*s %*s %*s %*s %*s %f');
    VSCOut.RhoMax = StrTemp{1};
else
    % Mean density
    VSCOut.RhoAvg = CalcAirDensity(VSCOut.TempAvg,VSCOut.SiteHeightAvg + VSCOut.HubHeightAvg);

    % Max density
    VSCOut.RhoMax = CalcAirDensity(VSCOut.TempMin,VSCOut.SiteHeightMin + VSCOut.HubHeightAvg);
end

% compensate for high density
VSCOut.RhoAvgFat = VSCOut.RhoAvg;
if VSCOut.RhoMax > VSCOut.RhoAvg*1.094
    VSCOut.RhoAvgExt = VSCOut.RhoMax/1.094;
else
    VSCOut.RhoAvgExt = VSCOut.RhoAvg;
end

% -- V50
VSCOut.keyV50 = 'Maximum 10 min. average wind speed';
pos = find(strncmpi(VSCOut.keyV50,C{1},length(VSCOut.keyV50)) == 1);
StrTemp  = textscan(C{1}{pos},'%*s %*s %*s %*s %*s %*s %*s %f');
VSCOut.V50 = StrTemp{1};

% -- Ve50
VSCOut.keyVe50 = 'Static gust wind speed (2 sec. mean)';
pos = find(strncmpi(VSCOut.keyVe50,C{1},length(VSCOut.keyVe50)) == 1);
StrTemp = textscan(C{1}{pos},'%*s %*s %*s %*s %*s %*s %*s %*s %f');
VSCOut.Ve50 = StrTemp{1};

% -- Ve50
keyV50Turb = 'Turbulence at extreme wind speed';
pos = find(strncmpi(keyV50Turb,C{1},length(keyV50Turb)) == 1);
StrTemp = textscan(C{1}{pos},'%*s %*s %*s %*s %*s %*s %f');
VSCOut.V50Turb = StrTemp{1}/100;

end

%% Print file
function PrintFile(VSCOut)
Filename = strrep(VSCOut.NAME,' ','_');
fid = fopen(fullfile(VSCOut.PATHSTR,[Filename VSCOut.FileNameExtemsion '.clm']),'wt+');
fprintf(fid,'Vestas Site Check Project Name: ''%s'' - %s is turbine label: ''%s'' - NTM_Fat: m = %4.2f\n',VSCOut.ProjectName, VSCOut.FatTopText, VSCOut.FatWLTLabel, VSCOut.TIefftWholer);
fprintf(fid,'ieced3  %i                              reference standard, windpar\n',VSCOut.PrepI);
fprintf(fid,'ieced3  %i 0.01 2                       iecgust windpar, iecgust turbpar, a (dummy if IECed3)\n',VSCOut.PrepI);
fprintf(fid,'VSCTable  0.01                         Turbulence standard, turbpar, a (dummy if IECed3), additional factor\n');
fprintf(fid,'0.0  0.0  0.0  0.0                     Iparked Ipark0, row spacing, park spacing\n');
fprintf(fid,'0.7   0.5                              I2,I3\n');
fprintf(fid,'%-5.1f                                  Terrain slope\n',mean(VSCOut.Inflow));
fprintf(fid,'%5.3f                                  Wind shear exponent\n',mean(VSCOut.WindShear));
fprintf(fid,'%5.3f %5.3f                            rhoext rhofat\n',VSCOut.RhoAvgExt,VSCOut.RhoAvgFat);
fprintf(fid,'%5.2f  %4.2f  20                        Vav  k  lifetime (for Weibull Calculation)\n',VSCOut.MeanW,VSCOut.Weibk);
fprintf(fid,'\n');
fprintf(fid,'SiteTurb\n');
fprintf(fid,'Vhub    	DETwind   	NTM_Fat   	NTM_Ext   	ETM       	WS_Prob  \n');
for i = 1:size(VSCOut.WindSpeed,2)
    fprintf(fid,'%2i  %2i  \t%-9.4f \t%-9.4f \t%-9.4f \t%-9.4f\n',VSCOut.VTSOut(:,i));
    % fprintf(fid,'%2i  %2i  \t%-9.4f \t%-9.4f \t%-9.4f \t%-9.4f \t%-9.4f\n',VSCOut.VTSOut(:,i));
end
fprintf(fid,'-1\n\n');
fprintf(fid,'Input for *.txt file: (copy beneath 4 lines into the text-file)\n');
fprintf(fid,'V50             %5.1f           based in VSC outfile: ''%s''\n',VSCOut.V50,VSCOut.keyV50);
fprintf(fid,'Ve50            %5.1f           based in VSC outfile: ''%s''\n',VSCOut.Ve50,VSCOut.keyVe50);
fprintf(fid,'V1              %5.1f           (0.80 x V50)\n',VSCOut.V50*0.8);
fprintf(fid,'Ve1             %5.1f           (0.80 x Ve50)\n',VSCOut.Ve50*0.8);
fprintf(fid,'\n\n');
fprintf(fid,'Based on VSCoutfile: %s\n',VSCOut.Outfile);
fprintf(fid,'*** VSCoutfile information ****************************\n');
for i = 1:length(VSCOut.VSCTopInfo)
    fprintf(fid,'%s\n',deblank(VSCOut.VSCTopInfo{i}));
end
fprintf(fid,'\n');
fprintf(fid,'Information on which turbine the turbulences are from:\n');
fprintf(fid,'Vhub    	DETwind   	NTM_Fat   	NTM_Ext   	ETM    \n');
for i = 1:11
    fprintf(fid,'%2i      \t%9s \t%9s \t%9s \t%9s\n',2+(i*2),VSCOut.MaxAmbTI90Label{i},VSCOut.FatWLTLabel,VSCOut.NTMextLabel{i},VSCOut.MaxETMLabel{i});
end
fprintf(fid,'\n******************************************************\n\n');

fprintf(fid,'Created by VSCoutToVTSclm.m MatLab-Script.\n');
fclose(fid);

disp(' ');
disp('VTS climate file created:');
disp(fullfile(VSCOut.PATHSTR,[Filename VSCOut.FileNameExtemsion '.clm']))

end

function Cprob = CumulativeWeibull(weibullA, weibullK, v)
    Cprob = 1 - exp(-(v / weibullA)^weibullK);
end

function prob = WeibullBinProbability(v, dV, weibullA, weibullK)
    prob = (CumulativeWeibull(weibullA, weibullK, v + dV / 2) - CumulativeWeibull(weibullA, weibullK, v - dV / 2));
end
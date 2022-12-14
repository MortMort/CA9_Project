

function outputname = VCSclimate2VTS(VSCsetupfile,climateFile,index,m,varargin)
% VCSclimate2VTS(VSCsetupfile,climateFile,index,m)
% Create WND files for a specific VSC climate
% The VSC calculates the climate using the equations in IEC 61400 Annex E.
% In equation E.3 it can be seen that the Ieff is a function of the
% Wohler curve exponent among other variables.
% NIWJO Nov 2020
%
% Required inptus
% VSCsetupfile  - that is the VSC_SetupInfo.txt file from a VSC setup
% climateFile   - that is the climate input file for VSC
% index         - that is the index number of the climate file giving the climate of
%                 interest
% m             - that is the Wholer coefficient of interest
%
% Optional inputs
% OutputName    - WND file output name full path
% PlotFig       - if fit wants to be seen default 0
%
% Use following input structure ...index,m,'OutputName',path,'PlotFig',1)
% Example
% VSCsetupfile = 'h:\Feasibility\Projects\001_NextGen_F0\Investigations\016_LFS-2963_update_F0_VSC_model\VSC\VSC_SetupInfo.txt';
% climateFile = 'h:\Feasibility\Projects\001_NextGen_F0\Investigations\019_LFS-3000_update_F0_VSC_climate_sweep\02_climates\DataDE.txt';
% index = 72;
% m = 8;
% VCSclimate2VTS(VSCsetupfile,climateFile,index,m,'PlotFig',1)

% default settings
plotfig = 0; outputname = [];

while ~isempty(varargin)
    switch lower(varargin{1})
        case 'plotfig'
            plotfig            = varargin{2};
            varargin(1:2) = [];
        case 'outputname'
            outputname            = varargin{2};
            varargin(1:2) = [];
        otherwise
            error(['Unexpected option: ' varargin{1}])
    end
end

% Create output file name if the outputname is not given as input
if isempty(outputname)
    [~,climateFileName] = fileparts(climateFile);
    outputname = fullfile(pwd,['WND_' climateFileName '_m=' num2str(m) '_index=' num2str(index) '.001']);
end
WNDtemplate = 'w:\ToolsDevelopment\VSC\SupportFiles\WND_VSC_template.txt';

% Read VSC Setup Info File
VSC_SetupInfo       = LAC.vsc.readVSC_SetupInfo(VSCsetupfile);

% Read VSC Climate File
climate             = LAC.vsc.import_VSC_Climate_file(climateFile);

% Calculation of Ieff
RelativeSpacingMin  = climate.RelativeSpacingMin(index);
airdensity          = climate.AirDensityAverage(index);
w_Amb               = 0.95; %95% contibution from Ambient Turbulence
w_Eff               = 0.05; %95% contibution from Wake Turbulence
Wind = [4 6 8 10 12 14 16 18 20 22 24];

for i = 1:length(Wind)
    TI_ambient(i) = climate.(['WS' num2str(Wind(i))])(index);
    TI_std(i)     = climate.(['WS' num2str(Wind(i)) '_1'])(index);
    a2sigmac      = TI_ambient(i)+1.28*TI_std(i);
    ct(i)         = getNearEstCtFromPcFile(VSC_SetupInfo.PowerFile,Wind(i),airdensity);
    b2            = 1/(1.5+0.8*RelativeSpacingMin/sqrt(ct(i)))^2;
    b3            = a2sigmac^2;
    B             = sqrt(b2+b3);
    TIeff(i)      = (w_Amb*a2sigmac^m+w_Eff*B^m)^(1/m);
end
disp('Values calculated from VSC data');
fprintf('%s  %s   %s       %s      %s\n','Wind','TI_ambient','TI_std','ct','TIeff')
for i = 1:length(Wind)
    fprintf('%4.0f  %4.3f        %6.3d  %6.2f  %6.2f\n',Wind(i),TI_ambient(i),TI_std(i),ct(i),TIeff(i))
end
fprintf('\n');

% Write values to WND file
WNDobj = LAC.vts.convert(WNDtemplate,'WND');


% [xData, yData] = prepareCurveData( Wind, TIeff );
% [fitresult, gof] = fit( xData, yData, fittype( 'smoothingspline' )); % Little overkill to use this function thus just taking linear
% extrapolation

a = (TIeff(2)-TIeff(1))/(Wind(2)-Wind(1));
b = TIeff(1)-a*Wind(1);
fitresult = @(x)(a*x+b);
gof.rsquare = NaN;

WNDwindspdavg = mean([[WNDobj.VSCtabel.WSs]' [WNDobj.VSCtabel.WSe]']');
for i = 1:length(WNDwindspdavg)
    if ~any(Wind == WNDwindspdavg(i))
        if WNDwindspdavg(i)>max(Wind)
            NTM_Fat(i) = a2sigmac(end);
            isfit(i)   = 0;
        else
            NTM_Fat(i) = fitresult(WNDwindspdavg(i));
            isfit(i)   = 1;
        end
    else
        NTM_Fat(i) = TIeff(Wind == WNDwindspdavg(i));
        isfit(i)   = 0;
    end
end
disp('Values for WND file:');
fprintf('%s  %s   %s \n','WNDwindspdavg','NTM_Fat','is fit used')
for i = 1:length(WNDwindspdavg)
    fprintf('%4.0f           %4.3f%6.0f\n',WNDwindspdavg(i),NTM_Fat(i),isfit(i))
end
fprintf('\n');

% Plot fit and resulting values
if plotfig
    figure;
    hold on; grid on;
    plot(Wind,TIeff,'-o')
    plot(WNDwindspdavg,fitresult(WNDwindspdavg),'-*')
    plot(WNDwindspdavg,NTM_Fat,'*')
    ylim([min(NTM_Fat)*0.9 max(NTM_Fat)*1.1])
    legend('Values from VSC climate',['FitResult R2 = ' num2str(gof.rsquare)],'Values for WND')
    xlabel('Wind Speed [m/s]');
    ylabel('Turbulence level');
end


WNDobj.Header = ['Wind (climate) parts file calculatede from VSC climate m = ' num2str(m) ' index = ' num2str(index)...
    ' with ID ' climate.VscProjectId{index} ' VSC climate file ' climateFile ...
    ' File generated with ' which('VCSclimate2VTS.m')];
for i = 1:length(NTM_Fat)
    WNDobj.VSCtabel(i).NtmFat = NTM_Fat(i);
end
WNDobj.k = num2str(climate.WeibullK(index));
WNDobj.Rhoext = num2str(climate.AirDensityAverage(index));
WNDobj.Rhofat = num2str(climate.AirDensityAverage(index));
WNDobj.Vav = num2str(climate.MeanWindSpeed(index),2);
WNDobj.TerrainSlope = num2str(climate.InflowAverage(index),2);
WNDobj.WindShearExponent = num2str(climate.WindShearAverage(index),2);
WNDobj.Lifetime = num2str(climate.DesignLifeTime(index));

WNDobj.encode(outputname);
warning('ONLY THE NTM_Fat have been updated in the Hybrid Table, thus the extreme values have to be calculated separate')
disp(['Location of new file: ' outputname]);

%% Funtions
    function ct = getNearEstCtFromPcFile(file,Wind,airdensity)
        %file = 'h:\Feasibility\Projects\001_NextGen_F0\Investigations\016_LFS-2963_update_F0_VSC_model\PC\Normal\nm_Vidar_F0_6400kW_HTST_HH143_TR-1.txt';
        
        % airdensity = 1.125;
        % Wind = 5.2;
        dataArray = textscan(fileread(file), '%s%[^\n\r]', 'Delimiter', '',  'ReturnOnError', false);
        
        pcData = dataArray{1};
        
        CTTabelDataRaw = pcData(find(contains(pcData,'#CT'))+6:find(contains(pcData,'#PITCH'))-2);
        CTTabelDensityRaw = pcData(find(contains(pcData,'#CT'))+4:find(contains(pcData,'#CT'))+4);
        CTTabelDensity = cellfun(@str2double,strsplit_LMT(CTTabelDensityRaw{1},' '));
        CTTabelDensity = CTTabelDensity(~isnan(CTTabelDensity));
        for ii = 1:length(CTTabelDataRaw)
            CTTabelDataRawSplit = strsplit_LMT(CTTabelDataRaw{ii},' ');
            CTTabelDataRawSplit = CTTabelDataRawSplit(~cellfun(@isempty,CTTabelDataRawSplit));
            CTTableWind(ii) = str2double(CTTabelDataRawSplit{1});
            CTTableData(ii,:) = cellfun(@str2double,CTTabelDataRawSplit(2:end));
        end
        CTTableWind = CTTableWind';
        [CTTabelDensitySort, CTTabelDensitySortIdx] = sort(CTTabelDensity);
        
        ct = interp2(CTTabelDensitySort,CTTableWind,CTTableData(:,CTTabelDensitySortIdx),airdensity,Wind);
    end
end

function [DLC11] = LoadExtrapolationSingleDistribution(SimPath,DLC11File,DLC13File,Options,Sensors,DLC13All,colors)

% Script for running a load extrapolation analysis:
%   - loads extremes from DLC1.3 and DLC1.1 (Run LoadExtrapolationPreProcessor.m to get the data in the good format)
%   - Does a fitting on the DLC1.1 extremes and extrapolates to the 50 year extreme load
%   - Summarises the results in a txt file if required
%   - Outputs the non exceedance probability plots as well as the fitting distributions and the 50 year extrapolated loads if required
%   - Outputs the results as a function of number of seeds required in DLC1.3 if required
% 
% Syntax:
%       LoadExtrapolationScript(DLC11File,DLC13File,Options,Sensors,DLC13All,colors)
% 
% Inputs:
%     - SimPath: Directory where the DLC11 and DLC13 cases have been simulated
%     - DLC11File: cell array of .mat file names containing the extremes of DLC1.1 (created with LoadExtrapolationPreProcessor.m)
%     - DLC13File: cell of the .mat file name containing the extremes of DLC1.3 (created with LoadExtrapolationPreProcessor.m)
%     - Options: structure containing some options for the load extrapolations
%     - Sensors: cell array containing the list of sensor names used for the load extrapolation
%     - DLC13All: structure containing information to help selecting seeds for DLC1.3 if extrapolated loads are too high
%     - colors: cell array of colors for the plots
% Outputs:
%     - No numeric outputs. Plots and txt report are generated if required
% Version history:
%     - 00: new script (DACA, 16/07/2013
%     - 01: updated script (MGMMI 07/2018)
% Review:
%     - 00: ?

%%
Py50    = 1/(50*365.25*24*6);      % corresponding probability of a return period of 50 year (for 10min simulation)
%% If DNV option is checked, make sure there is only one set of DLC11, tailfit and tailfitignore
if (Options.DNV==1) && ((length(DLC11File)~=1) || (length(Options.TailFit)~=1) || (length(Options.TailFitIgnore)~=1))
    disp('ERROR : DNV option checked. Make sure that only one set of DLC11, TailFit and TailFitIgnore is input');
    return;
end
if (Options.DNV==1)
    for i=1:size(Sensors,1)
        if sum([Sensors{i,3:5}])~=1
            disp('ERROR : DNV option checked. Make sure that one and only one fitting distribution is selected in the Sensors variables.');
            return;
        end
    end
end
%% Checks that files exist
for i=1:length(DLC11File)
    if ~strcmpi(DLC11File{i}(end-3:end),'.mat') 
        DLC11File{i} = [DLC11File{i},'.mat'];
    end
    if ~exist([DLC11File{i}],'file')
        disp(['ERROR : file ',DLC11File{i},' does not exist.']);
        disp('        Use LoadExt_LoadExtremesRun.m to generate the file');
        return;
    end
end
if ~exist(DLC13File,'file')
    disp(['ERROR : file ',DLC13File,' does not exist.']);
    disp('        Use LoadExt_LoadExtremesRun.m to generate the file');
    return;
end


%% Loads data and checks sensors
% Loads DLC11 data
DLC11   = cell(length(DLC11File),1);
for i=1:length(DLC11File)
    DLC11{i} = load(DLC11File{i}); DLC11{i}.File = DLC11File{i};
    if min(strcmpi(Sensors(:,1),(DLC11{i}.Sensors(:,1))))~=1
        disp(['WARNING: Sensors are different in ',DLC11File{i}]);  % A warning is prompted if sensors in DLC11 are different from the ones specified in the LoadExtrapolationRun script
    end
end

% Loads DLC13 data and rearrange them
tmp                 = load(DLC13File); 
DLC13.File          = DLC13File;
DLC13.Data          = tmp.DLC13.Data;
DLC13.Families      = tmp.DLC13.Families;
DLC13.ExtWS         = tmp.DLC13.ExtWS;
DLC13.Extremes      = tmp.DLC13.Extremes;
DLC13.Extremes3B    = tmp.DLC13.Extremes3B;
DLC13.Sensors       = tmp.Sensors;
DLC13.PathDLC13     = tmp.PathDLC13;
if min(strcmpi(Sensors(:,1),(DLC13.Sensors(:,1))))~=1
    disp(['WARNING: Sensors are different in ',DLC13File{i}]); % A warning is prompted if sensors in DLC13 are different from the ones specified in the LoadExtrapolationRun script
end


%% Call of fitting and extrapolation script
if length(DLC11File) > 1    % if there are more than 1 DLC11 setups, the fitting and the extrapolations are made on the first set of (TailFit TailFitIgnore)
    for i=1:length(DLC11File)
        DLC11{i}.Fitting(1,1).TailFit           = Options.TailFit(1);   % The fitting is made on extremes which have an exceedance probability between TailFitIgnore and TailFit
        DLC11{i}.Fitting(1,1).TailFitIgnore     = Options.TailFitIgnore(1);
        [DLC11{i}.Fitting(1,1).Results, DLC11{i}.PlotInputs(1,1)] = LoadExtrapolationFitting(DLC11{i}.ExtremesSorted,DLC11{i}.NonExceedanceProb,Options.TailFit(1),Options.TailFitIgnore(1),Sensors,Py50);

    end
else
    for i=1:length(Options.TailFit) % if there is only 1 DLC11 setup, the fitting and the extrapolations are made on all the sets of (TailFit TailFitIgnore)
        for j=1:length(Options.TailFitIgnore)
            DLC11{1}.Fitting(i,j).TailFit           = Options.TailFit(i);
            DLC11{1}.Fitting(i,j).TailFitIgnore     = Options.TailFitIgnore(j);
            [DLC11{1}.Fitting(i,j).Results, DLC11{1}.PlotInputs(i,j)] = LoadExtrapolationFitting(DLC11{1}.ExtremesSorted,DLC11{1}.NonExceedanceProb,Options.TailFit(i),Options.TailFitIgnore(j),Sensors,Py50);
        end
    end
end
% DLC11{:}.Fitting(:,:).Results includes parameters for the fitting curves
% and the 50 year extreme extrapolated loads
% DLC11{i}.PlotInputs(1,1) includes some inputs for the plots (TailFit and TailFitIgnore for example)
    
%% Report and Plots
% If an output file name is given in Options.OutFile, then a text file report is generated
if ~strcmpi(Options.OutFile,'') 
    LoadExtrapolationReport(SimPath,DLC11{1},DLC13,Options,Sensors);
end

% If required (OptionsDNV=1 or Options.Plots=1), then plots of the load
% distribution and the fitting curve are generated
TmpPlot = struct;
if Options.DNV ==1 % If plots are made to send to DNV, then only first sets of DLC11, TailFit and TailFitIgnore are taken into account. The DLC1.3 loads are not plotted, and extremes where fitting is applied are not highlighted. All plots will be black.
    Options.HighlightFitting = 0;
    Options.PlotDLC13 = 0;
    LoadExtrapolationPlots(SimPath,DLC11{1}.PlotInputs(1,1),Options,Sensors,DLC11{1}.Fitting(1,1),DLC13,DLC11{1}.Options.Legend,'k',1,TmpPlot);   
    LoadExtrapolationXLS(SimPath,DLC11{1}.Frq,DLC11{1}.Extremes,Sensors,DLC11{1}.Options.NExt,Options,DLC11{1}.File);
elseif Options.Plots
    if length(DLC11File) > 1
        Options.HighlightFitting = 0;
        for i=1:length(DLC11File)
            TmpPlot = LoadExtrapolationPlots(SimPath,DLC11{i}.PlotInputs(1,1),Options,Sensors,DLC11{i}.Fitting(1,1),DLC13,DLC11{i}.Options.Legend,colors{i},i,TmpPlot);
        end
    elseif length(Options.TailFit)==1 && length(Options.TailFitIgnore)==1
        LoadExtrapolationPlots(SimPath,DLC11{1}.PlotInputs(1,1),Options,Sensors,DLC11{1}.Fitting(1,1),DLC13,DLC11{1}.Options.Legend,colors{1},1,TmpPlot);
    else
        Options.HighlightFitting = 0;
        for i=1:length(Options.TailFit)
            for j=1:length(Options.TailFitIgnore)
                index = j+(i-1)*length(Options.TailFitIgnore);
                TmpPlot = LoadExtrapolationPlots(SimPath,DLC11{1}.PlotInputs(i,j),Options,Sensors,DLC11{1}.Fitting(i,j),DLC13,DLC11{1}.Options.Legend,colors{index},index,TmpPlot);
            end
        end
    end
end

%% Check required numbers of seeds in 1.3etm DLC in order to get extrapolated loads ratio OK
if ~strcmpi(DLC13All.Path,'')
    LoadExtrapolation13DLCTuning(DLC13All,DLC11{1}.Fitting(1,1).Results,Sensors);
end

end

function [Fitting,PlotInputs] = LoadExtrapolationFitting(ExtremesSorted,NonExceedanceProb,TailFit,TailFitIgnore,Sensors,Py50)

% Script which
%     - fits a Weibul, a Log-Normal and a Gumbel distribution to the tail of the exceedance probability distribution
%     - extrapolates the 50 year extreme loads  
%     - calculates the extrapolated 50 year extrapolated loads averaged over the 3 blades
% 
% Syntax:
%       [Fitting,PlotInputs] = LoadExtrapolationFitting(ExtremesSorted,NonExceedanceProb,TailFit,TailFitIgnore,Sensors,Py50)
% 
% Inputs:
%     - ExtremesSorted : array of extremes of time series, sorted in ascendent order. Generated by LoadExtrapolationPreProcessor.
%     - NonExceedanceProb: array of non exceedance probability. Order matches ExtremesSorted. Generated by LoadExtrapolationPreProcessor.
%     - TailFit: percentage of the tail where the distribution function should be fitted
%     - TailFitIgnore: percentage of the tail where the distribution function should NOT be fitted
%     - Sensors: cell array containing the list of sensor names used for the load extrapolation
%     - Py50: corresponding (10 min / 'n' extremes) probability of a return period of 50 year
%
% Outputs:
%     - Fitting: cell array containing, among others, the fitting distribution parameters and the extrapolated 50 year loads. Format is Fitting{sensor}.Type{1:3(distribution function type: logn,gbl,wbl3)}
%     - PlotInputs: includes some inputs for the plots (TailFit and TailFitIgnore for example)
%
% Version history:
%     - 00: new script (DACA, 16/07/2013
%     - 01: updated script (MGMMI 07/2018)
% Review:
%     - 00: ?

%% Fitting a candidate distribution
disttype={'logn','gbl','wbl3'};
NTailBegin = zeros(size(NonExceedanceProb,2),1);
NTailEnd = zeros(size(NonExceedanceProb,2),1);
Fitting = cell(size(NonExceedanceProb,2),1);
for i=1:size(NonExceedanceProb,2)
    NTailBegin(i)  = max(find(NonExceedanceProb(:,i)<1-TailFit,1,'last'));
    NTailEnd(i)    = max(find(NonExceedanceProb(:,i)<1-TailFitIgnore,1,'last'));
    for k=1:length(disttype)
        % Fitting curve
        [Fitting{i}.Type{k}.Params Fitting{i}.Type{k}.R] = LAC.statistic.lsqfit(disttype{k},NonExceedanceProb(NTailBegin(i):NTailEnd(i),i)',ExtremesSorted(NTailBegin(i):NTailEnd(i),i)');
        
        % 50 year load
        Fitting{i}.Type{k}.Extrapolated50 = fzero(@(x)(LAC.statistic.Xprob2(1,1,Fitting{i}.Type{k}.Params,x,1,disttype{k})-Py50),max(ExtremesSorted(:,i)));
    end
    Fitting{i}.Py50 = Py50;
end

%% Calculates mean of the 3 blades
for i=1:size(NonExceedanceProb,2)
    for k=1:length(disttype)
        index = [Sensors{:,2}]==Sensors{i,2};
        Fitting{i}.Type{k}.Extrapolated50_3B = 0;
        for l=1:length(index)
            Fitting{i}.Type{k}.Extrapolated50_3B = Fitting{i}.Type{k}.Extrapolated50_3B + Fitting{l}.Type{k}.Extrapolated50*index(l);
        end
        Fitting{i}.Type{k}.Extrapolated50_3B = Fitting{i}.Type{k}.Extrapolated50_3B/sum(index);
    end
end

PlotInputs.ExtremesSorted = ExtremesSorted;
PlotInputs.NonExceedanceProb = NonExceedanceProb;
PlotInputs.NTailBegin = NTailBegin;
PlotInputs.NTailEnd = NTailEnd;

end

function [] = LoadExtrapolationXLS(SimPath,Frq, Extremes,Sensors,Nextremes,Options,DLC11matfile)

% Function adjusted by YAYDE (10/09/2018) - checked MGMMI 11/09/2018
% loading data from stapost file to get the name of the time-series
% correspoing to each extreme, as well as the wind speed and quartile
load(DLC11matfile,'PathDLC11');
load([PathDLC11 filesep 'stapost.mat']);
filename=export.stadat.filenames;
wsIdx=strcmpi(export.stadat.sensor,'Vhfree');
wsraw=export.stadat.mean(wsIdx,:);
ws=round(2*wsraw')/2; % change to account for 1st decimal
quantiles=zeros(size(ws));
for ii=1:length(quantiles)
    qidx=strfind(filename{ii},'q');
    quantiles(ii,1)=str2double(filename{ii}(qidx+1:qidx+2));
end
%

h = actxserver('excel.application');
%Create a new work book (excel file)
wb = h.WorkBooks.Add();
% Delete old sheets
for i=1:h.Worksheets.Count-1
    h.Worksheets.Item(1).Delete;
end
set(h.Worksheets.Item(1),'Name','Extremes');
ActiveRange = get(h.Activesheet,'Range','A3'); set(ActiveRange, 'Value',  'Probability of the given extremes');
ActiveRange = get(h.Activesheet,'Range','B3'); set(ActiveRange, 'Value',  '-Mx11r');
ActiveRange = get(h.Activesheet,'Range','C3'); set(ActiveRange, 'Value',  '-Mx21r');
ActiveRange = get(h.Activesheet,'Range','D3'); set(ActiveRange, 'Value', '-Mx31r');
ActiveRange = get(h.Activesheet,'Range','E3'); set(ActiveRange, 'Value', 'My11r');
ActiveRange = get(h.Activesheet,'Range','F3'); set(ActiveRange, 'Value', 'My21r');
ActiveRange = get(h.Activesheet,'Range','G3'); set(ActiveRange, 'Value', 'My31r');
ActiveRange = get(h.Activesheet,'Range','H3'); set(ActiveRange, 'Value', 'Uy1');
ActiveRange = get(h.Activesheet,'Range','I3'); set(ActiveRange, 'Value', 'Uy2');
ActiveRange = get(h.Activesheet,'Range','J3'); set(ActiveRange, 'Value', 'Uy3');
ActiveRange = get(h.Activesheet,'Range','K3'); set(ActiveRange, 'Value', '-My11r');
ActiveRange = get(h.Activesheet,'Range','L3'); set(ActiveRange, 'Value', '-My21r');
ActiveRange = get(h.Activesheet,'Range','M3'); set(ActiveRange, 'Value', '-My31r');
ActiveRange = get(h.Activesheet,'Range','N3'); set(ActiveRange, 'Value', 'Simulation Name');
ActiveRange = get(h.Activesheet,'Range','O3'); set(ActiveRange, 'Value', 'Wind Speed');
ActiveRange = get(h.Activesheet,'Range','P3'); set(ActiveRange, 'Value', 'TI Quantile');

XLSindex = [find(strcmpi(Sensors(:,1),'-Mx11r')) ...
    find(strcmpi(Sensors(:,1),'-Mx21r')) ...
    find(strcmpi(Sensors(:,1),'-Mx31r')) ...
    find(strcmpi(Sensors(1:13,1),'My11r')) ...
    find(strcmpi(Sensors(1:13,1),'My21r')) ...
    find(strcmpi(Sensors(1:13,1),'My31r')) ...
    find(strcmpi(Sensors(:,1),'Uy1')) ...
    find(strcmpi(Sensors(:,1),'Uy2')) ...
    find(strcmpi(Sensors(:,1),'Uy3')) ...
    find(strcmpi(Sensors(14:16,1),'My11r'))+13 ...
    find(strcmpi(Sensors(14:16,1),'My21r'))+13 ...
    find(strcmpi(Sensors(14:16,1),'My31r'))+13];
    
XLSData = [Frq/sum(Frq) Extremes(:,XLSindex)];

cell1 = get (h.Activesheet.Cells,'Item',4,1);
cell2 = get (h.Activesheet.Cells,'Item',size(XLSData,1)+4-1,size(XLSData,2));
ActiveRange = get(h.Activesheet,'Range',cell1,cell2);
%JAMTS, here  all the extremes are copied
%to excell from Matrix XLSData[no seeds X Nextremes, 13]; where 13 are the
%following sensors: Probability of the given extremes,-Mx11r,-Mx21r,-Mx31r,My11r,My21r,My31r,Uy1,Uy2,Uy3,-My11r,-My21r,-My31r
set(ActiveRange, 'Value',  XLSData); 

counter=0;
filename_Nextremes = repelem(filename,Nextremes);%JAMTS 26/03/2019, correction for taking into account 6 extremes, 
ws_Nextremes = repelem(ws,Nextremes);%JAMTS 26/03/2019, correction for taking into account 6 extremes
quantiles_Nextremes = repelem(quantiles,Nextremes);%JAMTS 26/03/2019, correction for taking into account 6 extremes
%Loop copy the name of seeds in order, correction included for 6 extremes
for ic=1:size(XLSData,1)
counter=counter+1;
cell_name = get (h.Activesheet.Cells,'Item',3+ic,size(XLSData,2)+1);
ActiveRange = get(h.Activesheet,'Range',cell_name, cell_name);
set(ActiveRange, 'Value',  filename_Nextremes{ic}); %JAMTS name changed
end

cell1_wind = get (h.Activesheet.Cells,'Item',4,size(XLSData,2)+2);
cell2_wind = get (h.Activesheet.Cells,'Item',size(XLSData,1)+4-1,size(XLSData,2)+3);
ActiveRange = get(h.Activesheet,'Range',cell1_wind,cell2_wind);
set(ActiveRange, 'Value',  [ws_Nextremes quantiles_Nextremes]);%JAMTS name changed

ActiveRange = get(h.Activesheet,'Range','A1'); set(ActiveRange, 'Value', ['Number of extremes per time series: n(V) = ',num2str(Nextremes)]);
ActiveRange = get(h.Activesheet,'Range','A2'); set(ActiveRange, 'Value', 'The "probability of the given extremes" is the probability of the associated 10 minute time series, function of the wind speed probability distribution and the turbulence intensity probability distribution only.');

% save the file with the given file name, close Excel
wb.SaveAs([SimPath,'/',Options.OutFile,'_SingleD_Extremes.xlsx']);
wb.Close;
h.Quit;
h.delete;


end

function [] = LoadExtrapolationReport(SimPath,DLC11,DLC13,Options,Sensors)

% Generates a txt file with main results of the load extrapolation
% 
% Syntax:
%       [] = LoadExtrapolationReport(DLC11,DLC13,Options,Sensors)
% 
% Inputs:
%     - DLC11: cell array which includes the 50 year extrapolated loads. Generated by LoadExtrapolationFitting.
%     - DLC13: structure which includes the 1.3etm extreme loads
%     - Options: structure containing some options for the load extrapolations
%     - Sensors: cell array containing the list of sensor names used for the load extrapolation
%
% Outputs:
%     - No numerical outputs. A txt file is generated.
%
% Version history:
%     - 00: new script (DACA, 16/07/2013
%     - 01: updated script (MGMMI 07/2018)
% Review:
%     - 00: ?

%% Write results in txt file
fidout = fopen([SimPath Options.OutFile,'_SingleD.txt'],'w');
fprintf(fidout,date); fprintf(fidout,' - load extrapolation\n');
fprintf(fidout,'Path to NTM simulations : %s;\n', DLC11.PathDLC11);
fprintf(fidout,'Path to ETM simulations : %s;\n', DLC13.PathDLC13);
fprintf(fidout,'Number of extremes per time series: %i\n',DLC11.Options.NExt);
fprintf(fidout,'Tail fitting on data between %.6f and %.6f exceedance probability.\n',Options.TailFitIgnore(1),Options.TailFit(1));
fprintf(fidout,'-----------------------------------------------------------------------------------------------------------------------------\n');
fprintf(fidout,'In the table below:\n');
fprintf(fidout,'Loads are given without PLF. Ratio are given including PLF (1.35 for 1.3etm extreme loads, 1.25 for extrapolated loads)\n');
fprintf(fidout,'Rat1: ratio blade to maximum of 3 blades, for example (extrapolated(blade 1)*1.25)/(max(extreme(3 blades))*1.35).\n');
fprintf(fidout,'logn: log-normal, gbl: Gumbel, wbl3: 3 parameter Weibull.\n');
fprintf(fidout,'-----------------------------------------------------------------------------------------------------------------------------\n');
fprintf(fidout,'           | ETM load |      Log-Normal     |        Gumbel       |       Weibull       |\n');
fprintf(fidout,'    Sensor | (No PLF) |  Extrap.      Rat1  |  Extrap.      Rat1  |  Extrap.      Rat1  |\n');
for i=1:size(Sensors,1)
    if i < size(Sensors,1) -2
    fprintf(fidout,'%10s | %8.2f | %8.2f      %4.3f | %8.2f      %4.3f | %8.2f      %4.3f | \n',Sensors{i,1},DLC13.Extremes(i),...
        DLC11.Fitting(1,1).Results{i}.Type{1}.Extrapolated50,DLC11.Fitting(1,1).Results{i}.Type{1}.Extrapolated50*1.25/(DLC13.Extremes3B(i)*1.35),...
        DLC11.Fitting(1,1).Results{i}.Type{2}.Extrapolated50,DLC11.Fitting(1,1).Results{i}.Type{2}.Extrapolated50*1.25/(DLC13.Extremes3B(i)*1.35),...
        DLC11.Fitting(1,1).Results{i}.Type{3}.Extrapolated50,DLC11.Fitting(1,1).Results{i}.Type{3}.Extrapolated50*1.25/(DLC13.Extremes3B(i)*1.35));
    else 
    fprintf(fidout,'%10s | %8.2f | %8.2f      %4.3f | %8.2f      %4.3f | %8.2f      %4.3f | \n',['-' Sensors{i,1}],DLC13.Extremes(i),...
        DLC11.Fitting(1,1).Results{i}.Type{1}.Extrapolated50,DLC11.Fitting(1,1).Results{i}.Type{1}.Extrapolated50*1.25/(DLC13.Extremes3B(i)*1.35),...
        DLC11.Fitting(1,1).Results{i}.Type{2}.Extrapolated50,DLC11.Fitting(1,1).Results{i}.Type{2}.Extrapolated50*1.25/(DLC13.Extremes3B(i)*1.35),...
        DLC11.Fitting(1,1).Results{i}.Type{3}.Extrapolated50,DLC11.Fitting(1,1).Results{i}.Type{3}.Extrapolated50*1.25/(DLC13.Extremes3B(i)*1.35));        
    end

end
if Options.DNV
    fprintf(fidout,'---------------------------------------------------------------------------------------------------------------------------------------------\n');
    fprintf(fidout,'Outputs for documentation: Loads below are the 3 blades average of the selected distribution provided to DNV in addition to bladewise results\n');
    fprintf(fidout,'----------------------------------------------------------------------------|\n');
    fprintf(fidout,'           |  Ext. per   | Fitting | Extrap. value  |    ETM load   | Ratio |\n');
    fprintf(fidout,'    Sensor | time series |         | mean-PLF incl. | max-PLF incl. |       |\n');
    fprintf(fidout,'----------------------------------------------------------------------------|\n');
    Fitting = {'logn','gbl','wbl3'};
    % -Mx?1r
    IndexFamily = find(strcmp(Sensors(:,1),'-Mx11r') | strcmp(Sensors(:,1),'-Mx21r') | strcmp(Sensors(:,1),'-Mx31r'));
    IndexFitting = find([Sensors{IndexFamily(1),3:5}]==1);
    % check that the 3 sensors use the same fitting
    IndexFitting2 = find([Sensors{IndexFamily(2),3:5}]==1);
    IndexFitting3 = find([Sensors{IndexFamily(3),3:5}]==1);
    
    if IndexFitting2~=IndexFitting || IndexFitting3~=IndexFitting
        disp('Error, you should use the same fitting on sensors of the same family')
        return;
    end
    fprintf(fidout,'   -Mx?1r  | %6i      | %6s  | %11.2f    | %10.2f    | %4.3f | \n',DLC11.Options.NExt,Fitting{IndexFitting},...
        DLC11.Fitting(1,1).Results{IndexFamily(1)}.Type{IndexFitting}.Extrapolated50_3B*1.25,DLC13.Extremes3B(IndexFamily(1))*1.35,...
        DLC11.Fitting(1,1).Results{IndexFamily(1)}.Type{IndexFitting}.Extrapolated50_3B*1.25/(DLC13.Extremes3B(IndexFamily(1))*1.35));

    % My?1r
    IndexFamily = find(strcmp(Sensors(1:13,1),'My11r') | strcmp(Sensors(1:13,1),'My21r') | strcmp(Sensors(1:13,1),'My31r'));
    IndexFitting = find([Sensors{IndexFamily(1),3:5}]==1);
    % check that the 3 sensors use the same fitting
    IndexFitting2 = find([Sensors{IndexFamily(2),3:5}]==1);
    IndexFitting3 = find([Sensors{IndexFamily(3),3:5}]==1);
    
    if IndexFitting2~=IndexFitting || IndexFitting3~=IndexFitting
        disp('Error, you should use the same fitting on sensors of the same family')
        return;
    end
    fprintf(fidout,'    My?1r  | %6i      | %6s  | %11.2f    | %10.2f    | %4.3f | \n',DLC11.Options.NExt,Fitting{IndexFitting},...
        DLC11.Fitting(1,1).Results{IndexFamily(1)}.Type{IndexFitting}.Extrapolated50_3B*1.25,DLC13.Extremes3B(IndexFamily(1))*1.35,...
        DLC11.Fitting(1,1).Results{IndexFamily(1)}.Type{IndexFitting}.Extrapolated50_3B*1.25/(DLC13.Extremes3B(IndexFamily(1))*1.35));

    % Uy
    IndexFamily = find(strcmp(Sensors(:,1),'uy1') | strcmp(Sensors(:,1),'uy2') | strcmp(Sensors(:,1),'uy3'));
    IndexFitting = find([Sensors{IndexFamily(1),3:5}]==1);
    % check that the 3 sensors use the same fitting
    IndexFitting2 = find([Sensors{IndexFamily(2),3:5}]==1);
    IndexFitting3 = find([Sensors{IndexFamily(3),3:5}]==1);
    
    if IndexFitting2~=IndexFitting || IndexFitting3~=IndexFitting
        disp('Error, you should use the same fitting on sensors of the same family')
        return;
    end
    fprintf(fidout,'      Uy   | %6i      | %6s  | %11.2f    | %10.2f    | %4.3f | \n',DLC11.Options.NExt,Fitting{IndexFitting},...
        DLC11.Fitting(1,1).Results{IndexFamily(1)}.Type{IndexFitting}.Extrapolated50_3B*1.25,DLC13.Extremes3B(IndexFamily(1))*1.35,...
        DLC11.Fitting(1,1).Results{IndexFamily(1)}.Type{IndexFitting}.Extrapolated50_3B*1.25/(DLC13.Extremes3B(IndexFamily(1))*1.35));

    % -My?1r
    IndexFamily = find(strcmp(Sensors(14:end,1),'My11r') | strcmp(Sensors(14:end,1),'My21r') | strcmp(Sensors(14:end,1),'My31r'))+13;
    IndexFitting = find([Sensors{IndexFamily(1),3:5}]==1);
    % check that the 3 sensors use the same fitting
    IndexFitting2 = find([Sensors{IndexFamily(2),3:5}]==1);
    IndexFitting3 = find([Sensors{IndexFamily(3),3:5}]==1);
    
    if IndexFitting2~=IndexFitting || IndexFitting3~=IndexFitting
        disp('Error, you should use the same fitting on sensors of the same family')
        return;
    end
    fprintf(fidout,'   -My?1r  | %6i      | %6s  | %11.2f    | %10.2f    | %4.3f | \n',DLC11.Options.NExt,Fitting{IndexFitting},...
        -DLC11.Fitting(1,1).Results{IndexFamily(1)}.Type{IndexFitting}.Extrapolated50_3B*1.25,-DLC13.Extremes3B(IndexFamily(1))*1.35,...
        DLC11.Fitting(1,1).Results{IndexFamily(1)}.Type{IndexFitting}.Extrapolated50_3B*1.25/(DLC13.Extremes3B(IndexFamily(1))*1.35));
    
    
    fprintf(fidout,'----------------------------------------------------------------------------|\n');
end
fclose(fidout);


end

function [TmpPlot] = LoadExtrapolationPlots(SimPath,PlotInputs,Options,Sensors,Fitting,DLC13,Legend,color,Itr,TmpPlot)

% Generates plots of exceedance probabilities and fitting functions
% 
% Syntax:
%       [TmpPlot] = LoadExtrapolationPlots(PlotInputs,Options,Sensors,Fitting,DLC13,Legend,color,Itr,TmpPlot)
% 
% Inputs:
%     - PlotInputs: includes some inputs for the plots (TailFit and TailFitIgnore for example). Output from LoadExtrapolationFitting.
%     - Options: structure containing some options for the load extrapolations
%     - Sensors: cell array containing the list of sensor names used for the load extrapolation
%     - Fitting: cell array containing, among others, the fitting distribution parameters and the extrapolated 50 year loads. Output from LoadExtrapolationFitting.
%     - DLC13: structure which includes the 1.3etm extreme loads
%     - Legend: Legend for the given sets of DLC11
%     - color: color for the given sets of DLC11
%     - Itr: iteration number. Used internally.
%     - TmpPlot: Some internal parameters to ease the plotting. 
%
% Outputs:
%     - TmpPlot: Some internal parameters to ease the plotting. 
%
% Version history:
%     - 00: new script (DACA, 16/07/2013
%     
% Review:
%     - 00: ?

ExtremesSorted      = PlotInputs.ExtremesSorted;
NonExceedanceProb   = PlotInputs.NonExceedanceProb;
NTailBegin          = PlotInputs.NTailBegin;
NTailEnd            = PlotInputs.NTailEnd;


h_fig = 12;   %total height of figure
w_fig = 18;  %total width of figure
n_hor = 1;   %number of figures in the horizontal direction
n_ver = 1;   %number of figures in the vertical direction
d_vtop = 1.0; %vertical distance to top figure
d_vbot = 1.5; %vertical distance to bottom figure
d_hfir = 1.5; %horizontal distances to first column of figures
d_hlas = 0.5; %horizontal distances to last column of figures
d_vbet = 1.8;%vertical distance between figures
d_hbet = 1.5;%horizontal distance between figures
h_axis = (h_fig-d_vbot-d_vtop-d_vbet*(n_ver-1))/n_ver;    %height of axis
w_axis = (w_fig-d_hfir-d_hlas-d_hbet*(n_hor-1))/n_hor;    %width of axis

% Creates a folder if figures have to be saved
if Options.SaveFigs == 1
    FolderFigs = [SimPath 'Figures_' Options.NameStr '_SingleD'];
    mkdir(FolderFigs);
end

% Starts by creating empty figures
if Itr == 1
    for i=1:length(Sensors(:,1))
        if i < length(Sensors(:,1)) -2
            TmpPlot.Sensor(i).fig = figure('paperpositionmode', 'auto', 'units','centimeters','position', [5, 5, w_fig, h_fig],'color',[1 1 1],'name',Sensors{i,1});
        else
            TmpPlot.Sensor(i).fig = figure('paperpositionmode', 'auto', 'units','centimeters','position', [5, 5, w_fig, h_fig],'color',[1 1 1],'name',['- ' Sensors{i,1}]);            
        end
        axes('box', 'on', 'fontsize', 10,  'units', 'centimeters', 'position',[d_hfir, d_vbot+0*(d_vbet+h_axis), w_axis, h_axis], 'yscale','log'); hold on; grid on;
        ylabel('P(X>x|load case)');
        if i < length(Sensors(:,1)) -2
            xlabel(Sensors{i,1});
        else
            xlabel(['- ' Sensors{i,1}]);
        end
        title('Conditional cumulated exceedance probability');
    end
    TmpPlot.fig(i).Legends = {};
    TmpPlot.fig(i).p = [];
end

%% Plots
for i=1:length(Sensors(:,1))
    
    set(0, 'currentfigure', TmpPlot.Sensor(i).fig);
    
    TmpPlot.fig(i).p(end+1) = plot(ExtremesSorted(:,i),1-NonExceedanceProb(:,i),['.',color]);
    if Options.DNV==1
        TmpPlot.fig(i).Legends{end+1} = 'Empirical data';
    else
        TmpPlot.fig(i).Legends{end+1} = Legend;
    end
    
    if Sensors{i,3} == 1
        Xext = [ExtremesSorted(NTailBegin(i):end,i);(ExtremesSorted(end,i):(1.02*Fitting.Results{i}.Type{1}.Extrapolated50-ExtremesSorted(end,i))/100:1.02*Fitting.Results{i}.Type{1}.Extrapolated50)'];
        par=Fitting.Results{i}.Type{1}.Params;
        TmpPlot.fig(i).p(end+1) = plot(Xext,1-LAC.statistic.normalcdf(log(Xext),par(1),par(2)),['-',color]);
        if Options.DNV==1
            TmpPlot.fig(i).Legends{end+1} = 'Fitting function - logn';
        else
            TmpPlot.fig(i).Legends{end+1} = [Legend,[' - logn (',num2str(Fitting.TailFit),', ',num2str(Fitting.TailFitIgnore),') - R^2 = ',num2str(Fitting.Results{i}.Type{1}.R^2)]];
        end
    end
    
    if Sensors{i,4} == 1
        Xext = [ExtremesSorted(NTailBegin(i):end,i);(ExtremesSorted(end,i):(1.02*Fitting.Results{i}.Type{2}.Extrapolated50-ExtremesSorted(end,i))/100:1.02*Fitting.Results{i}.Type{2}.Extrapolated50)'];
        par=Fitting.Results{i}.Type{2}.Params;
        TmpPlot.fig(i).p(end+1) = plot(Xext,1-LAC.statistic.gblcdf(Xext,par(1),par(2)),['--',color]);
        if Options.DNV==1
            TmpPlot.fig(i).Legends{end+1} = 'Fitting function - gbl';
        else
            TmpPlot.fig(i).Legends{end+1} = [Legend,[' - gbl (',num2str(Fitting.TailFit),', ',num2str(Fitting.TailFitIgnore),') - R^2 = ',num2str(Fitting.Results{i}.Type{2}.R^2)]];
        end
    end
    
    if Sensors{i,5} == 1
        Xext = [ExtremesSorted(NTailBegin(i):end,i);(ExtremesSorted(end,i):(1.02*Fitting.Results{i}.Type{3}.Extrapolated50-ExtremesSorted(end,i))/100:1.02*Fitting.Results{i}.Type{3}.Extrapolated50)'];
        par=Fitting.Results{i}.Type{3}.Params;
        TmpPlot.fig(i).p(end+1) = plot(Xext,1-LAC.statistic.wbl3cdf(Xext,par(1),par(2),par(3)),[':',color]);
        if Options.DNV==1
            TmpPlot.fig(i).Legends{end+1} = 'Fitting function - wbl3';
        else
            TmpPlot.fig(i).Legends{end+1} = [Legend,[' - wbl3 (',num2str(Fitting.TailFit),', ',num2str(Fitting.TailFitIgnore),') - R^2 = ',num2str(Fitting.Results{i}.Type{3}.R^2)]];
        end
    end
    
    if Options.HighlightFitting == 1
        plot(ExtremesSorted(NTailBegin(i):NTailEnd(i),i),1-NonExceedanceProb(NTailBegin(i):NTailEnd(i),i),'.r');
    end
    
    switch Options.PlotDLC13
        case 1
            plot(DLC13.Extremes(i)*1.35/1.25,Fitting.Results{i}.Py50,'xr','MarkerSize',10,'LineWidth',2);
            plot(DLC13.Extremes(i)*1.35/1.25*1.03,Fitting.Results{i}.Py50,'xg','MarkerSize',10,'LineWidth',2);
        case 2
            plot(DLC13.Extremes3B(i)*1.35/1.25,Fitting.Results{i}.Py50,'xr','MarkerSize',10,'LineWidth',2);
            plot(DLC13.Extremes3B(i)*1.35/1.25*1.03,Fitting.Results{i}.Py50,'xg','MarkerSize',10,'LineWidth',2);
    end
    
    axs = get(gcf,'CurrentAxes');
    x=get(axs,'xlim');
    if Options.NExt == 1    
        axis([x(1) max([x(2),DLC13.Extremes3B(i)*1.35/1.25*1.05]) 1e-7 1]);
    elseif Options.NExt > 1
        axis([x(1) max([x(2),DLC13.Extremes3B(i)*1.35/1.25*1.05]) 1e-8 1]);
    end

    x=get(axs,'xlim');
    plot(x,[Fitting.Results{i}.Py50 Fitting.Results{i}.Py50],'-k');
    if Options.NExt == 1
        set(axs,'Ytick',[1e-7 1e-6 1e-5 1e-4 1e-3 1e-2 1e-1 1e0]);
    elseif Options.NExt > 1
        set(axs,'Ytick',[1e-8 1e-7 1e-6 1e-5 1e-4 1e-3 1e-2 1e-1 1e0]);
    end        
    set(axs, 'YMinorGrid','off');

    legend(TmpPlot.fig(i).p,TmpPlot.fig(i).Legends,'Location','Best');
   
    if Options.SaveFigs == 1
        if i < length(Sensors(:,1))-2
        saveas(TmpPlot.Sensor(i).fig, [FolderFigs '/' Sensors{i,1} '.fig']) %Matlab .FIG file
        saveas(TmpPlot.Sensor(i).fig, [FolderFigs '/' Sensors{i,1} '.emf']) %Windows Enhanced Meta-File (best for powerpoints)
        else
        saveas(TmpPlot.Sensor(i).fig, [FolderFigs '/-' Sensors{i,1} '.fig']) %Matlab .FIG file        
        saveas(TmpPlot.Sensor(i).fig, [FolderFigs '/-' Sensors{i,1} '.emf']) %Windows Enhanced Meta-File (best for powerpoints)        
        end
    end
end


end

function [] = LoadExtrapolation13DLCTuning(DLC13All,Fitting,Sensors)
% LoadExtrapolation13DLCTuning generates plots which helps choosing the
% number of seeds necessary in DLC.13 in order to make the 1.3 extreme
% loads large enough to match the extrapolated loads.
% 
% Syntax:
%       [] = LoadExtrapolation13DLCTuning(DLC13All,Fitting,Sensors)
% 
% Inputs:
%     - DLC13All: structure which includes path to the frequency file of simulations with 1.3etm LC with large number of seeds
%     - Fitting: cell array containing, among others, the fitting distribution parameters and the extrapolated 50 year loads. Output from LoadExtrapolationFitting.
%     - Sensors: cell array containing the list of sensor names used for the load extrapolation
%
% Outputs:
%     - No numerical outputs, but plots are generated
%
% Version history:
%     - 00: new script (DACA, 16/07/2013
% Review:
%     - 00: ?

sta = LAC.vts.stapost(fileparts(fileparts(DLC13All.Path)));
sta.read;

DLC13.Data = sta.stadat;
DLC13.Families = unique(sta.stadat.family)';
% number of seeds per family
NSeedsFamily = zeros(length(DLC13.Families),1);
for j=1:length(DLC13.Families)
    index = find(sta.stadat.family==DLC13.Families(j));
    NSeedsFamily(j) = length(index);
    for i=1:size(Sensors,1)
        idxSensor = sta.findSensor(Sensors{i,1});
        for k=1:NSeedsFamily(j)-DLC13All.SeedStart+1
            DLC13.ExtWS(i,j,k) = mean(DLC13.Data.max(idxSensor,index(DLC13All.SeedStart:DLC13All.SeedStart+k-1))); % Extreme of sensor i, family j for the first k seeds, starting from SeedStart.
        end
    end
end

% Maximum of families
for i=1:size(Sensors,1)
    for k=1:NSeedsFamily(j)-DLC13All.SeedStart
        DLC13.Extremes(i,k) = max(squeeze(DLC13.ExtWS(i,:,k))); % Maximum over the families (i.e. wind speeds)
    end
end

% Maximum of 3 blades
for i=1:size(Sensors,1)
        DLC13.Extremes3B(i,:) = max(DLC13.Extremes([Sensors{:,2}]==Sensors{i,2},:),[],1);
end

%% Plots blade to blade
for i=1:size(Sensors,1)
    % Makes sure there is only one fitting
    if sum([Sensors{i,3:5}])~=1
        disp('ERROR: Only one fitting (logn, wbl3, gbl) per sensor is allowed to perform the study regarding number of seeds in 1.3DLC (LoadExtrapolation13DLCTuning)');
        return;
    end
    FitType = [Sensors{i,3:5}]==1;
    figure('name',Sensors{i,1}); hold on; grid on; box on;
    plot(Fitting{i}.Type{FitType}.Extrapolated50*1.25./(DLC13.Extremes3B(i,:)*1.35))
    ylabel(Sensors{i});
    xlabel('Number of Seeds')
end

%% Plots max of 3 blades
SensorFamilies = unique([Sensors{:,2}]);
for i=1:length(SensorFamilies)
    tmp     = find([Sensors{:,2}]==i);
    Sens = tmp(1);
    FitType     = [Sensors{Sens,3:5}]==1;
    figure('name',[Sensors{tmp}]); hold on; grid on; box on;
    plot(Fitting{Sens}.Type{FitType}.Extrapolated50_3B*1.25./(DLC13.Extremes3B(Sens,:)*1.35))
    xlabel('Number of seeds')
    ylabel([Sensors{tmp}]);
    axs = get(gcf,'CurrentAxes');
    x=get(axs,'xlim');
    plot(x,[1.05 1.05],'-r','LineWidth',2);
    plot(x,[1.04 1.04],'-b','LineWidth',2);
end
end
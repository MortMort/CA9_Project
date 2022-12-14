function VSC_boxplot(SegmentData,varargin)
% VSC_boxplot(SegmentData,varargin)
% Required inputs
% - SegmentData cell structure with paths to the VSC result files
%
% Optional inputs
% - figureType      Can be Fatigue (default) or Extreme eg
%                   ...,'FigureType','Extreme')
% - quantileLim
% - plotlimits
% - FigTitle
% - figuresave       set if you want to write figure
% - figurelocation   set if you want to write figure to a specific
%                    location
% - inputdata        Specify input values eg InputDataFatigue = {
%                    'Bld','Blade'
%                    }
%                    will only plot Bld sensor and set Blade name on plot
% Example 1
%       LAC.vsc.VSC_boxplot({'test',{path to VSC result file}})
% Example 2
%       SegmentData = {
%               'SE' ,{'w:\USER\pgdmo\Siteability_ALKJA\F0B\03_load_results\LoadsSE.txt'};
%               'US',{'w:\USER\pgdmo\Siteability_ALKJA\F0B\03_load_results\LoadsUS_1.txt','w:\USER\pgdmo\Siteability_ALKJA\F0B\03_load_results\LoadsUS_2.txt'};
%                }
%       LAC.vsc.VSC_boxplot(SegmentData,'FigTitle','Sitebility F0B')
%
% Example 3
%       Pre populate SegmentData using the populateSegmentData function
%       meaning that the data dont have to be read twice if multiple plots
%       are created
%
%       SegmentData = {
%               'SE' ,{'w:\USER\pgdmo\Siteability_ALKJA\F0B\03_load_results\LoadsSE.txt'};
%               'US',{'w:\USER\pgdmo\Siteability_ALKJA\F0B\03_load_results\LoadsUS_1.txt','w:\USER\pgdmo\Siteability_ALKJA\F0B\03_load_results\LoadsUS_2.txt'};
%                }
%       SegmentData = populateSegmentData(SegmentData)
%       LAC.vsc.VSC_boxplot(SegmentData,'FigureType','Fatigue','FigTitle','Test','figuresave',1,'figurelocation',pwd)
%       LAC.vsc.VSC_boxplot(SegmentData,'FigureType','Extreme','FigTitle','Test','figuresave',1,'figurelocation',pwd)
%

%Default values
quantileLim = [0.05 0.2 0.8 0.95];
plot_limits = [60 125];
FigTitle = '';
figuresave = 0;
figurelocation = cd;
figureType = 'Fatigue';
InputData = '';

InputDataFatigue = {
   %'_','All';
    'Bld','Blade';
    'Hub_L','Blade Bearing';
    'Hub_m','Hub';
    'Rot_m','Main Bearing';
    'Rot_L','Gearbox';
    'Fix_m','Nacelle';
    'Nac_m','Nacelle';
    'Twr_m','Tower';
    'Fnd_m','Foundation';
    };

InputDataExtreme = {
    %'_','All';
    'Bld_','Blade';
    'Hub_','Hub';
    'Rot','Gearbox';
    'Fix_','Nacelle'; 
    'Nac','Nacelle';
    'Twr','Tower';
    'Fnd','Foundation';
    };

% hanlde for varargin

while ~isempty(varargin)
    switch lower(varargin{1})
        case 'quantilelim'
            quantileLim            = varargin{2};
            varargin(1:2) = [];
        case 'plotlimits'
            plot_limits            = varargin{2};
            varargin(1:2) = [];
        case 'figtitle'
            FigTitle            = varargin{2};
            varargin(1:2) = [];
        case 'figuresave'
            figuresave = varargin{2};
            varargin(1:2) = [];
        case 'figurelocation'
            figurelocation = varargin{2};
            varargin(1:2) = [];
       case 'inputdata'
            InputData = varargin{2};
            varargin(1:2) = [];
       case 'figuretype'
            figureType = varargin{2};
            varargin(1:2) = [];
        otherwise
            error(['Unexpected option: ' varargin{1}])
    end
end

% Read VSC data if not alreay read
if size(SegmentData,2) == 2
    SegmentData = LAC.vsc.populateSegmentData(SegmentData);
end

% Put into new variables for readability
PlotCountries = SegmentData(:,1);
if strcmpi(figureType,'fatigue')
    if isempty(InputData)
        InputData = InputDataFatigue;
    end
    PlotData = SegmentData(:,3);
    PlotSensor = SegmentData(:,4);
elseif strcmpi(figureType,'extreme')
    if isempty(InputData)
        InputData = InputDataExtreme;
    end
    PlotData = SegmentData(:,5);
    PlotSensor = SegmentData(:,6);
end

% Assuming same sensors in all files
[~,I] = min(cellfun(@numel,PlotSensor));
sensors = PlotSensor{I};

% used for removing sensors with low loads
Data = PlotData{I};

% Sort Lists
sortlist = InputData(:,1);

% Identify sensors to plot
plotIndex = []; k = 0;
for i = 1:length(sortlist)
    Index = find(~cellfun(@isempty,strfind(sensors,sortlist{i})));
    Sort = find(max(Data.data(:,Index)) > 10);
    if isempty(intersect(plotIndex,Index(Sort)))
        k = k+1;
        plotIndex = [plotIndex Index(Sort)];
        plotIndexSep{k} = Index(Sort);
        plotIndexStr{k} = strtrim(sensors(Index(Sort)));
    end
    if isempty(Sort)
        warning(['Sensors with "' sortlist{i} '" not found'])
    end
end

% Remove empty indexes
plotIndexSep = plotIndexSep(~cellfun(@isempty,plotIndexSep));

% generate data for plots
Data = []; group = [];
for iplot = 1:length(plotIndex)
    for iii = 1:length(PlotCountries)
        SubData = PlotData{iii}.data(1:end,plotIndex(iplot));
        q{iplot,iii} = LAC.vsc.quantile(SubData,quantileLim );
        Data = [Data; SubData];
        range = 1:size(PlotData{iii}.data,1);
        Temp(range) = {[strtrim(PlotSensor{iii}{plotIndex(iplot)}) '_[' PlotCountries{iii} ']' ]};
        group = [group,Temp];
        clear Temp;
    end
end

% plot data
scrsz = get(groot,'ScreenSize');
figure1 = figure('Position',[scrsz(4)/8 scrsz(3)/8 scrsz(3)/4*3 scrsz(4)/3*2]); axes('Parent',figure1,'Position',[0.0344 0.145 0.947 0.780]);
h = boxplot(Data,group); hold on; grid on;
set(gca,'FontSize',8,'XTickLabelRotation',90);
plot(xlim,[100 100],'-k','LineWidth',2)
ylim(plot_limits);
yl =  ylim;
ylabel('Rel load [%]');


%%% modify the figure properties (set the YData property)
%h(5,1) correspond the blue box
%h(1,1) correspond the upper whisker
%h(2,1) correspond the lower whisker
counter = 1;
for iplot = 1:length(plotIndex)
    for iii = 1:length(PlotCountries)
        qq = q{iplot,iii};
        set(h(5,counter), 'YData', [qq(2) qq(3) qq(3) qq(2) qq(2)]);% blue box
        
        upWhisker = get(h(1,counter), 'YData');
        set(h(1,counter), 'YData', [qq(3) qq(4)]);
        upWhisker = get(h(3,counter), 'YData');
        set(h(3,counter), 'YData', [qq(4) qq(4)]);
        dwWhisker = get(h(2,counter), 'YData');
        set(h(2,counter), 'YData', [ qq(1) qq(2)]);
        dwWhisker = get(h(4,counter), 'YData');
        set(h(4,counter), 'YData', [ qq(1) qq(1)]);
        counter = counter +1 ;
    end
end
set(h(7,:),'Visible','off')

% color the segment boxes
colors = lines;
h = findobj(gca,'Tag','Box');
jj = 1;
for j=length(h):-1:1
    p(jj) = patch(get(h(j),'XData'),get(h(j),'YData'),colors(jj,:));
    jj = jj+1;
    if jj > length(PlotCountries)
        jj = 1;
    end
end

% draw on the plot
start = 0.6;
for i = 1:length(plotIndexSep)
    LL = length(plotIndexSep{i})*length(PlotCountries);
    rectangle('Position',[start yl(1)+1 LL-0.2 diff(yl)-2],'EdgeColor','k','LineWidth',1,'LineStyle','--');
    text(start+(LL-0.2)/2,yl(1)+1+2,InputData{i,end},'HorizontalAlignment','center','FontSize',8) %Blade
    for ii = 1:length(plotIndexSep{i})
        step = length(PlotCountries);
        rectangle('Position',[start+0.1+step*(ii-1) yl(1)+5 step-0.4 diff(yl)-8],'EdgeColor','k','LineWidth',1,'LineStyle',':');
        %         text(start+step*(ii-1)+(step-0.4)/2+0.1,yl(1)+5+2,plotIndexStr{i}{ii},'HorizontalAlignment','center','FontSize',8) %Blade
    end
    start = start + LL;
end
Seg = '';
Points = 0;
for iii = 1:length(PlotCountries)
    Seg = [Seg ' ' PlotCountries{iii}];
    Points = Points + size(PlotData{iii}.data,1)-1;
end
title([FigTitle ' - Segments: ' Seg ' - On number of turbines: ' int2str(Points)])
legend(p, strcat(PlotCountries,' Turbines:',cellfun(@(x) num2str(size(x.data,1)),PlotData,'UniformOutput',0)));

if figuresave
    % Assume fatigue if m10 exist in the sensor list
    if any(contains(PlotSensor{1},'m10'))
        savefig(fullfile(figurelocation,['LoadOverviewFatigue_' strrep(Seg,' ','_')]));
        print(fullfile(figurelocation,['LoadOverviewFatigue_' strrep(Seg,' ','_')]),'-dmeta');
    else
        savefig(fullfile(figurelocation,['LoadOverviewExtreme_' strrep(Seg,' ','_')]));
        print(fullfile(figurelocation,['LoadOverviewExtreme_' strrep(Seg,' ','_')]),'-dmeta');
    end
end
end
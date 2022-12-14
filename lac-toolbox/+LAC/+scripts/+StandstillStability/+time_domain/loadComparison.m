function loadEnvelope(turbine,outfolder,turbname,bladeProps,bldloadpath,q_allowed,f_risk,ref_loads)
% Read blade edge loads from operational reference and compare to 
% rotor lock and idling modes (with all blades in parked/idling position).

config = turbine.config;
len = length(turbine.config);
for c=1:len        
if config(c).service_type == 2 % only idling or rotor locked modes.
    continue % next iteration
else    
% initialize
suffix={'Locked','Idle'};
ILString = {'lock','idle'};
intDir = [outfolder '/VTS/' config(c).case '/Loads/INT/'];
idleFlag = config(c).idleflag;  

% plot settings
imgSz=[700,420];
LW=2;

%% Establish reverse edge reference (operational) loads 
% reads and write reference reverse edge blade loads file (incl. PLF) if given
if bldloadpath
    blddat1 = textscan(fileread(bldloadpath),'%s%[^\n\r]', 'Delimiter', '');
    blddat = blddat1{1};

    MyMin_idx = find(contains(blddat,'Extreme Negative Edgewise Moment, Incl. PLF'));
    MyMin_idx_end = find(contains(blddat,'Extreme Positive Shear Force, Incl. PLF'));

    MyMin = blddat(MyMin_idx+3:MyMin_idx_end-1);

    fid = fopen([outfolder '/' ref_loads '/' turbname '_RevEdge_BLDLoads.csv'],'w');
    for i = 1:length(MyMin)
        MyMin_dat = textscan(MyMin{i},'%s %s %s %s %s %s %s %s%[^\n\r]');
        radius{i} = MyMin_dat{1,1}{1,1};
        My{i}     = MyMin_dat{1,3}{1,1};
        PLF{i}    = MyMin_dat{1,6}{1,1};
        fprintf(fid,'%s,%s,%s\n',radius{i},My{i},PLF{i});
    end
    fclose(fid);
end
end

% read reverse edge blade loads file (created manually or automatically)
if exist([outfolder '/' ref_loads '/' turbname,'_RevEdge_BLDLoads.csv'],'file') 
    REdata=csvread([outfolder '/' ref_loads '/' turbname,'_RevEdge_BLDLoads.csv'],1);
else
    error([outfolder '/' ref_loads '/' turbname,'_RevEdge_BLDLoads is not found! Blade loads can not be calculated.'])
end
Z = REdata(:,1);
MyDesign = REdata(:,2)./REdata(:,3); % Reverse edge load divided by PLF
    
%% Establish standstill reverse edge loads @recommended service wind 
% edge sensors
load('sensorList')
MySens = [];
for BNR = [1,3,2] 
    MySens = [MySens; find(strncmpi(['My' int2str(BNR)],sensorList,3)&...
        ~strncmpi(['My' int2str(BNR) '1r'],sensorList,5)&...
        ~strncmpi(['My' int2str(BNR) '1h'],sensorList,5)&...
        ~strncmpi(['My' int2str(BNR) 'P'],sensorList,4))'];
end

% extract the radii of the sensors with blade moment output
Rsens = [];
for ii = 2:length(bladeProps.SectionTable.R)
    if(~isempty(strfind(bladeProps.SectionTable.Out{ii},'.123')))
        Rsens = [Rsens ; bladeProps.SectionTable.R(ii)];
    end
end

if(length(Rsens) ~= length(MySens(1,:)))
    error('The number of blade sensors does not match the outputs found in the sensor file.')
end

% load distribution calculation
load([outfolder '/' f_risk '/' turbname '_' config(c).case '_' 'ZFac.mat']) % load only necessary stuff
load([outfolder '/' f_risk '/' turbname '_' config(c).case '_ReturnPeriod.mat'])

% select wind for 
if q_allowed(c).wsp > 0
    wsp = q_allowed(c).wsp;
    tag = 'Allowed';
elseif VTarget.WFAC > 0
    wsp = VTarget.WFAC;
    tag = 'Return';
else % arbitrery wsp
    wsp = 20;
    tag = 'Arbitrary';
end

PLoads = permute(Loads,[4,1,2,3]);  % permute loads matrices so that they can be interpolated
Linterp = interp1(wsps,PLoads,wsp,'linear','extrap'); % find interpolated loads matrix based on VTarget
WLoads = permute(Linterp,[2,3,4,1]); % re-permute back to original orientation

% locate id of worstcase .int-file
[Index.row,Index.col]=find(max(max(WLoads))==WLoads);

MaxInt.bld=ceil(Index.row/length(azim)); % which blade
if length(azim) == 1
    MaxInt.az = azim(1);
elseif Index.row == 3*length(azim)
    MaxInt.az = azim(1);
else
    MaxInt.az = azim(mod(Index.row,length(azim)));
end

MaxInt.ye=wdir(Index.col);
MaxInt.wd=MaxInt.ye;
MaxInt.mis = config(c).pitch_misalignment; % select worst pitch misaligned loads
MaxInt.wd(MaxInt.wd<0)=MaxInt.wd(MaxInt.wd<0)+360;
[~,wsInd]=min(abs(wsps-wsp));
MaxInt.ws=wsps(wsInd);
MaxInt.string = ['61SSS' ILString{config(c).idleflag+1} '_ws' num2str(MaxInt.ws) 'mis' int2str(MaxInt.mis) 'az' int2str(MaxInt.az) 'wd' int2str(MaxInt.wd) '.int']; %Modified by JAMTS 20/08/2019 to fit the LoadCasewriter

[dummy, t, dat] = LAC.timetrace.int.readint([intDir MaxInt.string],1,[],[],[]); % fix dir

RevEdge=zeros(1,length(Rsens));
FwdEdge=RevEdge;
for i=1:length(Rsens)
    [RevEdge(i),revEind]=min(dat(:,MySens(MaxInt.bld,i)));
    [FwdEdge(i),fwdEind]=max(dat(:,MySens(MaxInt.bld,i)));
end

save([outfolder '/' ref_loads '/' turbname '_LoadEnvelope_' config(c).case],'Rsens','RevEdge','FwdEdge','WLoads','VTarget','wsp','tag')

%% Plotting
% reverse edge loads to operational reference
figure
hold off
REint=interp1(Rsens,RevEdge,Z,'pchip'); % SSS maximum edge load
p1=plot(Z,REint,'b','LineWidth',LW);
xlabel('\bfBlade radius [m]')
title(sprintf('%s SSS to reference - Rotor %s',turbname,suffix{idleFlag+1}),'FontSize',14,'FontWeight','Bold','Interpreter','none')
hold on
[ax,p2,p3]=plotyy(Z,MyDesign,Z,REint./MyDesign);
set(p2,'color','r','LineWidth',LW)
set(p3,'color','g','LineWidth',LW)
set(ax,'YColor','k')

radiusBelow90Pct = (Rsens(end) * 0.9) > Rsens; %Find indices where radius is less than 90% (high values towards the tip can cause graph scaline issues)
maxAxVal = ceil(max(REint(radiusBelow90Pct)./MyDesign(radiusBelow90Pct)));
set(ax(2),'ylim',[0,maxAxVal],'ytick',[0:0.5:maxAxVal])

ylabel(ax(2),'\bfEV Loads : Design Loads Ratio','FontSize',12)
ylabel(ax(1),'\bfBending Moment Distribution [kNm]','FontSize',12)
legend([p1,p2,p3],{['EV Load Envelope - Rotor ',suffix{idleFlag+1}],'Reverse Edge Reference Loads','EV/Design Ratio'},'Location','SouthEast')
set(gcf,'Position',[100,100,imgSz])
print(gcf,[outfolder '/' ref_loads '/' turbname '_DesignLoadComparison_' suffix{idleFlag+1},'.png'],'-dpng')
close
end
end



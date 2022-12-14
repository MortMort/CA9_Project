function [turbI, frq]=DLCgenerator(Vave,wsp,Iref,quan,seedstr,outdir,plotIT,kfac,design_life,edType,LCoptionString)

% Load Case txt-file generator for load extrapolation
%
% syntax:
%       [turbI, frq]=DLCgenerator()
%       [turbI, frq]=DLCgenerator(Vave,Vbin,Iref,quan,seedstr)
%       [turbI, frq]=DLCgenerator(Vave,Vbin,Iref,quan,seedstr,outdir,plotIT)
%       [turbI, frq]=DLCgenerator(Vave,Vbin,Iref,quan,seedstr,outdir,plotIT,kfac)
%       [turbI, frq]=DLCgenerator(Vave,Vbin,Iref,quan,seedstr,outdir,plotIT,kfac,LCoptions)
%       [turbI, frq]=DLCgenerator(8.5,[4:2:22],0.14,[0.15 0.5 0.85 0.97],'1 - 60')
%
% input:
%       outdir = location of output txt-file (default = cd)
%       Vave = Average wind speed in a k=2 parameter Weibull distribution
%       wsp = Wind speed bins center value, eg. Vbin=4:2:24. Bin size is deffined by diff(Vbin)
%       Iref = Expected turbulence intensity at 15 m/s. IECA=0.16 IECB=0.14 IECC=0.12
%       quan = Discretisation of the turbulence intensity by means of the
%              quantiles. Eg. quan=[0.15 0.5 0.85 0.97]
%       seedstr = String defining the number of seed. eg. '1 - 60', 'a - g'.
%       outdir =  output directory. default is cd.
%       PlotIT = 0/1. Plot distributions.
%       kfac = k factor in the wind speed distribution Weibull parameters. If omitted, k=2.0;
%       design_life = 20
%       LCOptionString = additional LC optioons as a string
% Output:
%       txt-file with load case definitions
%       turbI = turbulence intensity matrix
%       frq = frequency matrix
%
% Purpose:
%       The purpose of the function is to generate load case definitions for
%       prep input txt-file. The function will bin in quantile of
%       the IEC lognormal turbulence distribution.
%
% Quality control
% Created by:
% v00:      SORSO 31/08/2010
% v01:      SORSO 28/09/2010 (fleet data included)
% v02:      SORSO 07/03/2011 (trimed for tltoolbox, only IEC turb dist)
% v03:      DACA 06/03/2012 (Printing DLC, bug-fixed in line 103)
% v04:      DACA 20/06/2014 (add k factor as a parameter)
% v05:      MIFAK 29/08/2018 (add design life as a parameter, introduce IEC 61400-1 edt. 4 turbulence distribution and correct turbulence rounding error)
% v06:      JADGR 26/10/2018 (Add support for custom loadcase options and non-integer wind speeds
% 
% Review by:
% v00:
% v01:
% v02:
% v03: 
% v05: MJR (design-life implementation) / SORSO (IEC 61400-1 edt. 4 implementation)
% V06: MJR

%%

if nargin<8
    kfac = 2;
end
if nargin<9
    design_life = 20;
end
if nargin<10
    edType = 'ed3';
end
if nargin<11
    LCoptionString = '';
end

if nargin<6
    outdir=strcat(cd,'\'); % output dir
    plotIT=1;
end

disp(['Output dir: ',outdir])

%Todo does not update with number of seeds!
lifetime=design_life*365.25*24*6;        % No. 10 min series

if nargin==0
    Vave=10; %m/s
    wsp=4:2:24;                 % 10 min. mean wind speed. used for bining
    quan=[0.15 0.5 0.85 0.97];    % quantile of the turbulence distribution. used for bining
    Iref=0.16;
    seedstr='1 - 60';
end

if plotIT
    figure;
end

for iWsp = 1:length(wsp)
    if strcmp(edType, 'ed3')
        mux = Iref*(0.75*wsp(iWsp)+3.8);	% IEC ed3 dist.
        sigx = Iref*1.4;                    % IEC ed3 dist.
        [turbI(iWsp,:), turb] = LAC.climate.ntm(Iref,wsp(iWsp),quan,'ed3');
        frq(iWsp,:) = LAC.statistic.probbin(turb,mux,sigx,1,'logn');
    elseif strcmp(edType, 'ed4')
        A = Iref*(0.75*wsp(iWsp)+3.3);  % scale factor (eq. 12 in IEC 61400-1 edt. 4)
        k = 0.27*wsp(iWsp)+1.4;         % shape factor (eq. 12 in IEC 61400-1 edt. 4)
        mux = A*gamma(1+1/k);           % average value from scale factor
        sigx = k;
        [turbI(iWsp,:), turb] = LAC.climate.ntm(Iref,wsp(iWsp),quan,'ed4');
        frq(iWsp,:) = LAC.statistic.probbin(turb,mux,sigx,1,'wbl');
    end
end


%% Write out file

fname='11fNameDef.txt'; %filename


line1 = '11xxx1 Prod. Wdir=0';
line2 = 'ntm xxx5 Freq xxx2 LF 1.35';
line3 = '0.1 2 xxx4 0 turb xxx3';
for i=1:size(frq,2)
    frq(:,i)=frq(:,i).*LAC.statistic.probbin(wsp,Vave,kfac,0,'wbl')'*lifetime;
end
disp(['total time: ',num2str(sum(sum(frq))/lifetime*design_life),' years']);
outdir=strcat(outdir);
if ~strcmpi(outdir(end),'\')
    outdir=strcat(outdir,'\');
end



fid=fopen(strcat(outdir,fname),'w');
fprintf(fid,'*** 1.1: Turbulence distribution on Iref %1.2f site \n\n',Iref);
for j=1:size(turbI,2)
    for i=1:length(wsp)
        
        qua=quan(j)*100;
        wind=wsp(i);
        
        rep1 = [num2str(wind,'%2.1f'),'q',num2str(qua,'%02.0f')];

        rep2=num2str(frq(i,j),7);     % replaces xxx2 in line
        rep3=num2str(turbI(i,j),'%.3f');    % replaces xxx3 in line
        rep4=num2str(wsp(i));       % replaces xxx4 in line
        
        % Generate output line:
        oline1=strrep(line1,'xxx1',rep1);
        oline2=strrep(line2,'xxx2',rep2);
        oline2=strrep(oline2,'xxx5',seedstr);
        oline3=strrep(line3,'xxx3',rep3);
        oline3=strrep(oline3,'xxx4',rep4);
        
        % Write to txt-file
        fprintf(fid,'%s \n',oline1);
        fprintf(fid,'%s \n',oline2);
        fprintf(fid,'%s %s\n\n',oline3,LCoptionString);
    end
end
fclose(fid);
if plotIT
    h=plot(wsp,frq(:,:),'.-');
    xlabel('wind speed')
    ylabel('frq ')
    qtxt=['qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqq']';
    legend(h,[qtxt(1:length(quan)),num2str(quan','%1.2f')])
    figure
    h=plot(wsp,turbI(:,:),'.-');
    xlabel('wind speed')
    ylabel('TI')
    legend(h,[qtxt(1:length(quan)),num2str(quan','%1.2f')])
    
end
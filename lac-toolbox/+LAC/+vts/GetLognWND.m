function GetLognWND(WNDFile)
% Function to modify WND file part to match new format of "LNTable" and run 
% prep with DLC 11 quantiles based on a lognormal distribution, as per [1]  
% A modified WND file is created, including the "LNTable" identifier and
% the two additional columns "LN_MEAN" and "LN_STD", calculated based on
% the expressions from [2]
%
% [1] http://wiki.tsw.vestas.net/display/LACWIKI/Log+Normal+in+LaC+Too+Chain
% [2] 0088-2565.V00 - Annex B
%
% SYNTAX:
% 	LAC.vts.GetLognWND(WNDFile)
%
% INPUTS:
% 	WNDFile - Full path to the baseline WND file
%
% OUTPUTS:
%	1. Modified prep file ('_LN_Mod'), placed in same folder as the input file
%   2. Plot with TI for the three quantiles (30%, 90%, 99%) calculated based
%   on the original WND file parameters and the modified WND file ones(LN_Mean, LN_STD)
%
% VERSIONS:
% 	2021/03/26 - AAMES: V00
%   2021/09/15 - AAMES: V01 - Add support for standard WND files + plot of TI calculated by the LN method

%% Get data from WND file
WND = LAC.vts.convert(WNDFile,'WND');
if ~isempty(WND.VSCtabel)
    NtmFat = [WND.VSCtabel.NtmFat]';
    Ws = median([[WND.VSCtabel.WSs]' [WND.VSCtabel.WSe]'], 2);
    Iref = NtmFat./(0.75+5.6./Ws);
else
    wsBinWidth = 1;
    Ws = 2:wsBinWidth:50;
    WSs = Ws - wsBinWidth/2;
    WSe = Ws + wsBinWidth/2;
    Iref = WND.TurbPar .* ones(size(Ws));
    NtmFat = Iref .* (0.75 + 5.6./Ws);
    Etm = ( 2 .* Iref .* ( 0.072.*( WND.Vav/2 + 3 ).*( Ws/2 -4) + 10 ) )./Ws;
end

%% Calculate E, V (expected value, variance) of the logn distribution of WS std
% Logn distribution of the standard deviation of the wind speed (standard climate)
% Expressions (1),(2) from [2]
E = Iref.*(0.75.*Ws+3.8);
V = (1.4.*Iref).^2;

%% Calculate mean (M_TI) and standard deviation (S_TI) of logn distribution of TI
% Logn distribution of the turbulence intensity
% Parameters related to E, V through the wind speed (TI requires to divide by WS)
% Relation between expressions (3)-(7), (4)-(8) in [2] 
LN_Mean = zeros(size(Ws)); LN_Std = zeros(size(Ws));
for i = 1:length(Ws)
    LN_Mean(i) = E(i)/Ws(i);
    LN_Std(i) = sqrt(V(i))/Ws(i);
end

%% Logn distribution parameters, calculated from E, V (for checks only)
% Expressions (3),(4) from [2]
sigma = zeros(size(Ws)); mu = zeros(size(Ws));
for i = 1:length(Ws)
    sigma(i) = (log((V(i)/(E(i)^2))+1))^0.5;
    mu(i) = log(E(i)) - 0.5*(sigma(i)^2) - log(Ws(i));
end

%% Logn distribution parameters, calculated from M_TI, S_TI (for checks only)
% Expressions (7),(8) from [2]
sigma_LN = zeros(size(Ws)); mu_LN = zeros(size(Ws));
for i = 1:length(Ws)
    sigma_LN(i) = (log((LN_Std(i)/LN_Mean(i))^2+1))^0.5;
    mu_LN(i) = log(LN_Mean(i)) - 0.5*(LN_Std(i)^2) ;
end

%% TI quantiles - Calculated from sigma, mu (for final checks only)
% Expression (11), from [2]
turb30 = zeros(size(Ws)); turb90 = zeros(size(Ws)); turb99 = zeros(size(Ws));
for i = 1:length(Ws)
    turb30(i) = exp(mu(i)+sqrt(2*(sigma(i)^2))*erfinv(2*0.3-1));
    turb90(i) = exp(mu(i)+sqrt(2*(sigma(i)^2))*erfinv(2*0.9-1));
    turb99(i) = exp(mu(i)+sqrt(2*(sigma(i)^2))*erfinv(2*0.99-1));
end

%% TI quantiles - Calculated from sigma_LN, mu_LN (for final checks only)
% Expression (11), from [2]
% 'turbXX_LN' values should match closely to 'turbXX' calculated before
turb30_LN = zeros(size(Ws)); turb90_LN = zeros(size(Ws)); turb99_LN = zeros(size(Ws));
for i = 1:length(Ws)
    turb30_LN(i) = exp(mu_LN(i)+sqrt(2*(sigma_LN(i)^2))*erfinv(2*0.3-1));
    turb90_LN(i) = exp(mu_LN(i)+sqrt(2*(sigma_LN(i)^2))*erfinv(2*0.9-1));
    turb99_LN(i) = exp(mu_LN(i)+sqrt(2*(sigma_LN(i)^2))*erfinv(2*0.99-1));
end

%% Copy WND file and modify
NewFile = strrep(WNDFile,'.','_LN_Mod.');
copyfile(WNDFile,NewFile);

if ~isempty(WND.VSCtabel)
    %% WND files with VSCtable
    % Read baseline file txt data
    final_wnd_data = fileread(NewFile);
    % Get new table - Columns: WspeedS' WspeedE' DETWind NTMFat NTMExt ETM LN_MEAN LN_STD
    WspeedS = [WND.VSCtabel.WSs]';
    WspeedE = [WND.VSCtabel.WSe]';
    turb_NtmFat = [WND.VSCtabel.NtmFat]';
    turb_NtmExt = [WND.VSCtabel.NtmExt]';
    turb_Etm = [WND.VSCtabel.Etm]';
    new_data = sprintf('\r\n%.3f\t%.3f\t%.3f\t%.3f\t%.3f\t%.3f\t%.3f\t%.4f\t%.4f',...
        [WspeedS WspeedE turb_NtmExt turb_NtmFat...
        turb_NtmExt turb_Etm ones(length(WspeedS),1) LN_Mean LN_Std]');
    % Change VSC to LN Table
    final_wnd_data = strrep(final_wnd_data,'VSCTable','LNTable');
    final_wnd_data = strrep(final_wnd_data,'additional factor','additional factor, quantile');
    % Change turbulence table values
    ch_headers = strfind(final_wnd_data,'WS_Prob');
    ch_final = strfind(final_wnd_data,'-1');
    WND_write = [ final_wnd_data(1:ch_headers+6) new_data sprintf('\r\n') final_wnd_data(ch_final:end) ];
    % Change header table
    WND_write = regexprep(WND_write,'WS_Prob','WS_Prob\tLN_MEAN\tLN_STD ');
    % Change LN Table line
    LineLNtab = regexp(WND_write,'LNTable \d.\d* \d* \d*','match');
    newLineLNtab = [LineLNtab{1} ' 3'];
    WND_write = regexprep(WND_write,'LNTable \d.\d* \d* \d*',newLineLNtab);
else
    %% Standard WND files
    % Read file by lines
    fid = fopen(NewFile,'r');
    wnd_data = textscan(fid,'%s','Delimiter','\n');
    fclose(fid);
    wnd_data = wnd_data{1,1};
    % Change headings
    indLNtable = find(~cellfun(@isempty,strfind(wnd_data,'Turbulence standard')));
    lineLNtable = strsplit(wnd_data{indLNtable},' ');
    lineLNtable{1} = 'LNTable';
    wnd_data{indLNtable} = [strjoin(lineLNtable(1:4)) ' 3' ...
        regexp(wnd_data{indLNtable},'\s\s+','match','once') strjoin(lineLNtable(5:end)) ', quantile'];
    % Add table - Columns: WspeedS' WspeedE' DETWind NTMFat NTMExt ETM LN_MEAN LN_STD
    WspeedS = WSs';
    WspeedE = WSe';
    turb_Ntm = NtmFat';
    turb_Etm = Etm';
    TurbTable = sprintf('\r\n%.3f\t%.3f\t%.3f\t%.3f\t%.3f\t%.3f\t%.3f\t%.4f\t%.4f',...
        [WspeedS WspeedE turb_Ntm turb_Ntm...
        turb_Ntm turb_Etm ones(length(WspeedS),1) LN_Mean' LN_Std']');
    newHeader = sprintf('\r\nSiteTurb\r\nVhub\tDETwind\tNTM_Fat\tNTM_Ext\tETM\tWS_Prob\tLN_MEAN\tLN_STD');
    tableFinal = [newHeader TurbTable sprintf('\r\n-1\r\n') ];
    % Get final data to write
    WND_write = [ sprintf('%s\r\n',wnd_data{:}) tableFinal ];
end

% Write modified file
fid = fopen(NewFile,'w');
fwrite(fid,WND_write);
fclose(fid);

%% Plot TI for 3 quantiles - from standard and logn parameters
figure('Name', 'TI check')
% 30% quantile
subplot(1,3,1)
plot(Ws,turb30,'-*','linewidth',1.2);
hold on;
plot(Ws,turb30_LN,'-o','linewidth',1.2);
grid on;
xlabel('Wind Speed [m/s]')
ylabel('TI (NTM) [-]')
title('30% quantile')
legend({'From Iref','From LN_MEAN, LN_STD'},'interpreter','none')
% 90% quantile
subplot(1,3,2)
plot(Ws,turb90,'-*','linewidth',1.2);
hold on;
plot(Ws,turb90_LN,'-o','linewidth',1.2);
grid on;
xlabel('Wind Speed [m/s]')
ylabel('TI (NTM) [-]')
title('90% quantile')
legend({'From Iref','From LN_MEAN, LN_STD'},'interpreter','none')
% 99% quantile
subplot(1,3,3)
plot(Ws,turb99,'-*','linewidth',1.2);
hold on;
plot(Ws,turb99_LN,'-o','linewidth',1.2);
grid on;
xlabel('Wind Speed [m/s]')
ylabel('TI (NTM) [-]')
title('99% quantile')
legend({'From Iref','From LN_MEAN, LN_STD'},'interpreter','none')
set(gcf, 'units','normalized','outerposition',[0.1 0.2 0.85 0.6]);
annotation('textbox',[0.3 0.04 0 0],'String','Modified WND file created. Accuracy check: TI here plotted should be fairly similar between the two calculation methods.','FitBoxToText','on','LineStyle','none','FontWeight','Bold');
end
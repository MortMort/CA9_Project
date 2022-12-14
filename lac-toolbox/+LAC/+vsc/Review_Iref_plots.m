function Review_Iref_plots(mode,save_path,paths,labels)
%% extreme Iref curve comparison plots
% mode - can be either 'compare' (compare two curves), or 'LaPM' (plot
% Irefs from LaPMs)
% save_path - path to output folder;
% paths - full path to Irefcurve.txt files;
% labels - plot legend;
%
% example input for 'compare' mode:
%
% paths = {...
%   'h:\ENVENTUS\Mk1a\Variants\F3\Investigations\119_ES_VSC\6500_119_IEC_STD_LATAM\00\VSC\ExtremeNorm\Irefcurve_20220224_040516\Irefcurve.txt' ,...
%   'h:\ENVENTUS\Mk1a\Variants\F3\Investigations\119_ES_VSC\6800_119_IEC_STD_LATAM\00\VSC\ExtremeNorm\Irefcurve_20220224_011710\Irefcurve.txt' };
%
% labels = {'Current Model (Ref.[1])','Previous Model (Ref.[2])'};
%
% example input for 'LaPM' mode:
%
% paths = {'h:\3MW\Mk3E6\Investigations\173_VSC_RegularSelling_50Hz\V150_IEC3B_HH105.0_VAS_AAO_PSA_T966915\VSC\ExtremeNorm\Irefcurve_20220215_013125\Irefcurve.txt',...
%   'h:\3MW\Mk3E6\Investigations\173_VSC_RegularSelling_50Hz\V150_IEC3B_HH105.0_VAS_AAO_PSA_T966915\VSC\PLO0_FLO1_ExtremeNorm\Irefcurve_20220215_014626\Irefcurve.txt',...
%   'h:\3MW\Mk3E6\Investigations\173_VSC_RegularSelling_50Hz\V150_IEC3B_HH105.0_VAS_AAO_PSA_T966915\VSC\PLO0_FLO2_ExtremeNorm\Irefcurve_20220215_015402\Irefcurve.txt',...
%   'h:\3MW\Mk3E6\Investigations\173_VSC_RegularSelling_50Hz\V150_IEC3B_HH105.0_VAS_AAO_PSA_T966915\VSC\NM11_ExtremeNorm\Irefcurve_20220215_020120\Irefcurve.txt',...
%   'h:\3MW\Mk3E6\Investigations\173_VSC_RegularSelling_50Hz\V150_IEC3B_HH105.0_VAS_AAO_PSA_T966915\VSC\NM12_ExtremeNorm\Irefcurve_20220215_020816\Irefcurve.txt',...
%   'h:\3MW\Mk3E6\Investigations\173_VSC_RegularSelling_50Hz\V150_IEC3B_HH105.0_VAS_AAO_PSA_T966915\VSC\NM13_ExtremeNorm\Irefcurve_20220215_021548\Irefcurve.txt'};
% 
% labels = {'Mode0','LO1','LO2','SO11', 'SO12', 'SO13'};



% Call function
switch mode
    case 'compare'
        CompareIref(paths,labels, [0.13 0.13], save_path)
    case 'LaPM'
        LaPMPlotsIref(paths,labels, [ 0.13 0.13 0.13 0.13 0.13 0.13], save_path)
end
end
%% Functions
function CompareIref(paths, labels, design_iref, save_path)

cmap = lines(length(paths));

curves = cell(length(paths), 1);
curves_cor = cell(length(paths), 1);
for iPath = 1:length(paths)
    fid = fopen(paths{iPath});
    temp = textscan(fid, '%s', 'delimiter', '\n');
    fclose(fid);
    
    wsp = textscan(temp{1}{2}, '%f', 'delimiter', ' ', 'multipledelimsasone', 1);
    iref = textscan(temp{1}{3}, '%f', 'delimiter', ' ', 'multipledelimsasone', 1);
    curves{iPath} = [wsp{1}, iref{1}];
    curves_cor{iPath} = [wsp{1}, max(iref{1}, repmat(design_iref(iPath)*100, length(iref{1}), 1))];
end
figure('position', [50, 50, 1200, 500])
subplot(1, 2, 1)
set(gcf,'color','w');
hold on
for iPath = 1:length(paths)
    plot(curves_cor{iPath}(:, 1), curves_cor{iPath}(:, 2), 'o-', 'markerSize',5,'LineWidth',1.2, 'color', cmap(iPath, :))
end
hold off
grid on
legend(labels, 'location', 'best')
xlabel('Wind speed [m/s]')
ylabel('Iref [%]')
subplot(1, 2, 2)
set(gcf,'color','w');
hold on
for iPath = 2:length(paths)
    plot(curves_cor{iPath}(:, 1), (curves_cor{iPath}(:, 2)./curves_cor{1}(:, 2)-1)*100, 'o-', 'markerSize',5,'LineWidth',1.2, 'color', cmap(iPath, :))
end
hold off
grid on
%tightfig;
legend(labels(2:end), 'location', 'best')
xlabel('Wind speed [m/s]')
ylabel('Diff. [%]')

fname = 'Iref_comparison';
%[pathstr, ~, ~] = fileparts(paths{1});
%print(fullfile(pathstr, [fname, '.emf']), '-dmeta')
saveas(gcf, fullfile(save_path, fname), 'emf')
saveas(gcf, fullfile(save_path, fname), 'fig')

% fid = fopen(fullfile(pathstr, [fname, '.txt']), 'w');
% for iPath = 1:length(paths)
%     fprintf(fid, '%-27s - %s\r\n', sprintf('(%s)', labels{iPath}), paths{iPath});
% end
% fclose(fid);
end

function LaPMPlotsIref(paths, labels, design_iref, save_path)

cmap = lines(length(paths));

curves = cell(length(paths), 1);
curves_cor = cell(length(paths), 1);
for iPath = 1:length(paths)
    fid = fopen(paths{iPath});
    temp = textscan(fid, '%s', 'delimiter', '\n');
    fclose(fid);
    
    wsp = textscan(temp{1}{2}, '%f', 'delimiter', ' ', 'multipledelimsasone', 1);
    iref = textscan(temp{1}{3}, '%f', 'delimiter', ' ', 'multipledelimsasone', 1);
    curves{iPath} = [wsp{1}, iref{1}];
    curves_cor{iPath} = [wsp{1}, max(iref{1}, repmat(design_iref(iPath)*100, length(iref{1}), 1))];
end
figure('position', [50, 50, 800, 600])
%subplot(1, 2, 1)
set(gcf,'color','w');
hold on
for iPath = 1:length(paths)
    plot(curves_cor{iPath}(:, 1), curves_cor{iPath}(:, 2), 'o-', 'markerSize',5,'LineWidth',1.2, 'color', cmap(iPath, :))
end
hold off
grid on
legend(labels, 'location', 'best')
xlabel('Wind speed [m/s]')
ylabel('Iref [%]')
% subplot(1, 2, 2)
% set(gcf,'color','w');
% hold on
% for iPath = 2:length(paths)
%     plot(curves_cor{iPath}(:, 1), (curves_cor{iPath}(:, 2)./curves_cor{1}(:, 2)-1)*100, 'o-', 'markerSize',5,'LineWidth',1.2, 'color', cmap(iPath, :))
% end
% hold off
% grid on
%tightfig;
% legend(labels(2:end), 'location', 'best')
% xlabel('Wind speed [m/s]')
% ylabel('Diff. [%]')

fname = 'Iref_LaPM';
% [pathstr, ~, ~] = fileparts(paths{1});
% print(fullfile(pathstr, [fname, '.emf']), '-dmeta')
saveas(gcf, fullfile(save_path, fname), 'emf')
saveas(gcf, fullfile(save_path, fname), 'fig')

% fid = fopen(fullfile(pathstr, [fname, '.txt']), 'w');
% for iPath = 1:length(paths)
%     fprintf(fid, '%-27s - %s\r\n', sprintf('(%s)', labels{iPath}), paths{iPath});
% end
% fclose(fid);
end
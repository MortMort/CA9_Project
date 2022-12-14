function Plot_CaptureMatrix(WTG, CaptureMatrix)

    WS_BinCen = (WTG.CutInWSP - 1) : WTG.WSBinSize : WTG.CutOutWSP;    
    n_rows    = length(CaptureMatrix.CapturMatrx(:, 1));

    CaptureMatrix.CapturMatrx(n_rows + 1, :) = sum(CaptureMatrix.CapturMatrx, 1);

    figNo = 1;
    figure('Name', int2str(figNo), 'units', 'normalized', 'outerposition', [0 0 1 1]);
    figname1 = strcat('CaptureMatrix.fig');
    figname2 = strcat('CaptureMatrix.png');
    
    bar(WS_BinCen, CaptureMatrix.CapturMatrx(end, :));
    
    hold on
    grid on;
    set(gca, 'XTick', WS_BinCen, 'FontSize', 14);
    xlabel('Bin Wind speed normalised (m/s)', 'FontSize', 16);
    xlim([(WS_BinCen(1) - 0.5) (WS_BinCen(end) + 0.5)]);
    ylabel('No. of samples per bin', 'FontSize', 16);
    title(['Capture Matrix, Total campaing hours: ', num2str(floor(sum(CaptureMatrix.CapturMatrx(end, :))/6))], 'FontSize', 16);
    
    plot([(WS_BinCen(1) - 0.5) (WS_BinCen(end) + 0.5)], [3 3], '--r') ;
    plot([WS_BinCen(1) WS_BinCen(1)], [0 max(CaptureMatrix.CapturMatrx(end,:))], ':m', 'LineWidth', 2.0);
    plot([WS_BinCen(3) WS_BinCen(3)], [0 max(CaptureMatrix.CapturMatrx(end,:))], ':g', 'LineWidth', 2.0);
    plot([WS_BinCen(end) WS_BinCen(end)], [0 max(CaptureMatrix.CapturMatrx(end,:))], ':k', 'LineWidth', 2.0);
    
    legend('No. of samples per bin', 'Minimum data required per bin', 'V_{IN - 1}', 'V_{IN}', 'V_{OUT}')%, 'FontSize', 14);
    
    saveas(figNo, [pwd '\Output_Figures\' figname1]);
    saveas(figNo, [pwd '\Output_Figures_PNG\' figname2]);
    close;
    
    
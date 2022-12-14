function [logd_pos logd_neg]=damping(signal,cut,fig)
% [logd_pos logd_neg]=damping(signal,fig)
% 
% Function to find peaks in a signal and calculate the logarithmic
% decrement. The decrement is calculated for the positive and negative
% peaks. The signal has to oscillate around 0. The findpeaks function has
% to be tuned to the type of signal.
%
% Inputs
% signal    = the signal which is investigated
% fig       = display fit?
%
% Outputs
% logd_pos  = log dec of positive peaks
% logd_neg  = log dev of negative peaks
%
% Revision:
% 10/3 MAARD: Initial version (not reviewed)

t=1:length(signal);

peaks_neg=LAC.signal.findpeaks(t,-signal,0,cut,5,5,3);
peaks_pos=LAC.signal.findpeaks(t,signal,0,cut,5,5,3);

x0 = [1.8 -0.2] ;

% Fit positive peaks
x_pos = fitcurve(x0,peaks_pos(:,1),peaks_pos(:,3));
logd_pos = -x_pos(2);
yfit_pos = x_pos(1)*exp(x_pos(2)*peaks_pos(:,1));

% Fit negative peaks
x_neg = fitcurve(x0,peaks_neg(:,1),peaks_neg(:,3));
logd_neg = -x_neg(2);
yfit_neg = x_neg(1)*exp(x_neg(2)*peaks_neg(:,1));

if nargin==3
    figure
    plot(t,signal); hold on; grid on;
    plot(peaks_neg(:,2),peaks_neg(:,3),'*r');
    plot(peaks_neg(:,2),-peaks_neg(:,3),'or');
    plot(peaks_neg(:,2),yfit_neg,'r-');
    plot(peaks_pos(:,2),peaks_pos(:,3),'*g');
    plot(peaks_pos(:,2),yfit_pos,'g-');
end
end

function [x, model, fx] = fitcurve(x0,xdata, ydata)

    model = @exp_error;
    x = fminsearch(model, x0);
    fx = model(x);

    function [sse] = exp_error(x)
        fx = x(1)*exp(x(2)*xdata);
        %sse = std(ydata'-fx);
        ErrorVector = fx-ydata;
        sse = sum(ErrorVector .^ 2);
    end

end
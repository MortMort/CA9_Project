function plotMovingFFT_single(filename,sensor,frq_range,max_FFT,RPM_sensor,wind_sensor)

filecontent = vdat('convert', filename);
out=movingFFT(filecontent.Xdata,filecontent.Ydata(:,sensor),1,10);
t=out.t;
frq=out.frq;
fft=out.fft;
%%
% figure
% plot(frq(2:end),fft(10,2:end)); grid on;
% xlim([0 8]); xlabel('Frequency [Hz'); ylabel('time [s]')

figH(1)=figure; set(figH(1),'color','white'); set(figH(1), 'Position', [120 75 750 500]);
subplot(1,7,1:6)
contourf(frq(2:end),t,fft(:,2:end),linspace(0,max_FFT,10)); hold on
xlim(frq_range); xlabel('Frequency [Hz]');ylabel('time [s]')
if nargin>4
    plot(LAC.rpm2rad(filecontent.Ydata(:,RPM_sensor))./(2*pi).*3,filecontent.Xdata,':w','linewidth',2);
    plot(LAC.rpm2rad(filecontent.Ydata(:,RPM_sensor))./(2*pi).*6,filecontent.Xdata,':w','linewidth',2);
    plot(LAC.rpm2rad(filecontent.Ydata(:,RPM_sensor))./(2*pi).*9,filecontent.Xdata,':w','linewidth',2);
end
title('Sensor')

if nargin>4
    subplot(1,7,7)
    plot(filecontent.Ydata(:,RPM_sensor),filecontent.Xdata); grid on; hold on
    xlabel('Rotor Speed [RPM]'); 
end

[path,fn,ext]=fileparts(filename);
if nargin>5
    exchange.suptitle(['Wind Speed=' num2str(mean(filecontent.Ydata(:,wind_sensor))) ', file=' strrep(fn,'_','-') ext]);
else
    exchange.suptitle(['File=' strrep(fn,'_','-') ext]);
end
    
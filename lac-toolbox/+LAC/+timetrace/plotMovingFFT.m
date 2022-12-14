function plotMovingFFT(filename,sensors,RPM_sensor,wind_sensor)

filecontent = vdat('convert', filename);
[t1,frq1,fft1]=movingFFT(filecontent.Xdata,filecontent.Ydata(:,sensors(1)),2,20);
[t2,frq2,fft2]=movingFFT(filecontent.Xdata,filecontent.Ydata(:,sensors(2)),2,20);
[t3,frq3,fft3]=movingFFT(filecontent.Xdata,filecontent.Ydata(:,sensors(3)),2,20);
%%
% figure
% plot(frq3(2:end),fft3(10,2:end)); grid on;
% xlim([0 8]); xlabel('Frequency [Hz'); ylabel('time [s]')

figH(1)=figure; set(figH(1),'color','white'); set(figH(1), 'Position', [120 75 1500 500]);

ax(1)=subplot(1,7,1:2);
contourf(frq1(2:end),t1,fft1(:,2:end),[linspace(0,10,10)]); hold on
xlim([0.5 2]); xlabel('Frequency [Hz]');ylabel('time [s]')
plot(LAC.rpm2rad(filecontent.Ydata(:,RPM_sensor))./(2*pi).*3,filecontent.Xdata,':w','linewidth',2);
plot(LAC.rpm2rad(filecontent.Ydata(:,RPM_sensor))./(2*pi).*6,filecontent.Xdata,':w','linewidth',2);
plot(LAC.rpm2rad(filecontent.Ydata(:,RPM_sensor))./(2*pi).*9,filecontent.Xdata,':w','linewidth',2);
title('Edge Moment, 38m')

ax(2)=subplot(1,7,3:4);
contourf(frq2(2:end),t2,fft2(:,2:end),[linspace(0,350,10)]); hold on
xlim([0.5 2]); xlabel('Frequency [Hz]');
plot(LAC.rpm2rad(filecontent.Ydata(:,RPM_sensor))./(2*pi).*3,filecontent.Xdata,':w','linewidth',2);
plot(LAC.rpm2rad(filecontent.Ydata(:,RPM_sensor))./(2*pi).*6,filecontent.Xdata,':w','linewidth',2);
plot(LAC.rpm2rad(filecontent.Ydata(:,RPM_sensor))./(2*pi).*9,filecontent.Xdata,':w','linewidth',2);
title('Tilt Moment')

ax(3)=subplot(1,7,5:6);
contourf(frq3(2:end),t3,fft3(:,2:end),[linspace(0,0.06,10)]); hold on
xlim([0.5 2]); xlabel('Frequency [Hz]')
plot(LAC.rpm2rad(filecontent.Ydata(:,RPM_sensor))./(2*pi).*3,filecontent.Xdata,':w','linewidth',2);
plot(LAC.rpm2rad(filecontent.Ydata(:,RPM_sensor))./(2*pi).*6,filecontent.Xdata,':w','linewidth',2);
plot(LAC.rpm2rad(filecontent.Ydata(:,RPM_sensor))./(2*pi).*9,filecontent.Xdata,':w','linewidth',2);
title('S-S acceleration')
linkaxes(ax,'xy');

subplot(1,7,7)
plot(filecontent.Ydata(:,RPM_sensor),filecontent.Xdata); grid on; hold on
xlabel('Rotor Speed [RPM]'); 

[path,fn,ext]=fileparts(filename);
exchange.suptitle(['Wind Speed=' num2str(mean(filecontent.Ydata(:,wind_sensor))) ', file=' strrep(fn,'_','-') ext]);
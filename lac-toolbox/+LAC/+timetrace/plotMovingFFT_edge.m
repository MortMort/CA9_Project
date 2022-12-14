function figH = plotMovingFFT_edge(filename,sensors)
yLimits=[0.1 2.5];

tsample = 0.05; frqsample = 0.05;

[GenInfo,Xdata,Ydata] = LAC.timetrace.int.readint(filename,1,[],[],[]);
[a,b,c]=LAC.rot2fix(LAC.deg2rad(Ydata(:,sensors.PSI)),Ydata(:,sensors.A),Ydata(:,sensors.B),Ydata(:,sensors.C));
fixed = LAC.signal.spectrogram(Xdata,c,2,20);

t_discretizer = max([1,round(tsample/mean(diff(Xdata)))]);
t_discretizerContour = max([1,round(tsample/mean(diff(fixed.t)))]);
frq_discretizer = max([1,round(frqsample/mean(diff(fixed.frq)))]);
%% Get local maxima of FFT
rotating = LAC.signal.spectrogram(Xdata,Ydata(:,sensors.C),2,20);
t=rotating.t;frq=rotating.frq; fftval=rotating.fft;
frq_sub=frq(frq>yLimits(1)&frq<yLimits(2));
fft_sub=fftval(:,frq>yLimits(1)&frq<yLimits(2));

[fft_max, i_max]=max(fft_sub,[],2);
frq_max=frq_sub(i_max);

oneP = mean(fft_max(frq_max<0.3));
cross1p = t(find(fft_max>2*oneP,1,'first'));
%%
figH=figure; set(figH,'color','white'); set(figH, 'Position', [120 75 1200 700]);
ContourLimits=linspace(0,1200,10);

ax(1)=subplot(2,3,1:2);
contourf(fixed.t(1:t_discretizerContour:end),fixed.frq(find(fixed.frq>yLimits(1),1,'first'):frq_discretizer:find(fixed.frq>yLimits(2),1,'first')),fixed.fft(1:t_discretizerContour:end,find(fixed.frq>yLimits(1),1,'first'):frq_discretizer:find(fixed.frq>yLimits(2),1,'first'))',ContourLimits); hold on
plot(Xdata(1:t_discretizer:end),LAC.rpm2rad(Ydata(1:t_discretizer:end,sensors.RPM))./(2*pi).*3,':w','linewidth',2);
plot(Xdata(1:t_discretizer:end),LAC.rpm2rad(Ydata(1:t_discretizer:end,sensors.RPM))./(2*pi).*6,':w','linewidth',2);
plot(Xdata(1:t_discretizer:end),LAC.rpm2rad(Ydata(1:t_discretizer:end,sensors.RPM))./(2*pi).*9,':w','linewidth',2);
plot(t,frq_max,'r.');
title('Edge root spectrogram, fixed system')
xlim([min(Xdata) max(Xdata)])
ylim(yLimits); ylabel('Frequency [Hz]')

ax(2)=subplot(2,3,3);
plot(Xdata(1:t_discretizer:end),Ydata(1:t_discretizer:end,sensors.RPM)); grid on; hold on
if ~isempty(cross1p)
    plot(Xdata(find(Xdata>cross1p,1,'first')),Ydata(find(Xdata>cross1p,1,'first'),sensors.RPM),'or')
    title(['Critical RPM: ' num2str(Ydata(find(Xdata>cross1p,1,'first'),sensors.RPM))])
end
ylabel('Rotor Speed [RPM]'); 

ax(3)=subplot(2,3,4:5);
plot(t,fft_max); grid on;hold on;
if ~isempty(cross1p)
    plot(t(fft_max>2*oneP),fft_max(fft_max>2*oneP),'.r')
end
ylabel('FFT Peak'); xlabel('Time [s]')
title('FFT magnitude, rotating system (B2)')

% Frequencies
ax(4)=subplot(2,3,6);
plot(Xdata(1:t_discretizer:end),Ydata(1:t_discretizer:end,sensors.C)/1000,'-'); grid on; hold on
xlabel('Time [s]'); ylabel('Edge Load x 1000 [kNm]')
title('Edge Load, (B2)')

linkaxes(ax,'x');

[path,fn,ext]=fileparts(filename);
suptitle(['Wind Speed=' num2str(mean(Ydata(:,sensors.WS))) ', file=' strrep(fn,'_','-') ext]);


% figure
% spectrogram(b,2000,1800,[],1/mean(diff(Xdata)),'MinThreshold',40); xlim([0.5 3])
% view(-77,72)
% shading interp
% colorbar off

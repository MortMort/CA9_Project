function out=plotFFTpeaks(filename,frq_range,sensor)
% plotFFTpeaks(filename,frq_range,sensor)
% 
% Inputs: 
%     filename    - full path to timeserie
%     frq_range   - frequency range to plot []
%     sensor      - sensornumber to process
% 
% Outputs:
%     out.fft_max - local fft peaks
%     out.frq_max - frq for local fft peaks
%     out.FFT_max - global fft peaks
%     out.FRQ_max - frq for global fft peaks
%     


%% Read file
filecontent = vdat('convert', filename);
%% Get local maxima of FFT
movFFT=movingFFT(filecontent.Xdata,filecontent.Ydata(:,sensor),2,30);
t=movFFT.t;frq=movFFT.frq; fft=movFFT.fft;
frq_sub=frq(frq>frq_range(1)&frq<frq_range(2));
fft_sub=fft(:,frq>frq_range(1)&frq<frq_range(2));

[fft_max, i_max]=max(fft_sub,[],2);
frq_max=frq_sub(i_max);

%% Get global max fft
dt=filecontent.Xdata(2)-filecontent.Xdata(1);
[FRQ,FFT]=fftcalc(filecontent.Xdata,filecontent.Ydata(:,sensor),round(60/dt));

FFT_sub=FFT(FRQ>frq_range(1)&FRQ<frq_range(2));
FRQ_sub=FRQ(FRQ>frq_range(1)&FRQ<frq_range(2));

[FFT_max, I_max]=max(FFT_sub);
FRQ_max = FRQ_sub(I_max);

%% Plot figures

% Peak levels
figH=figure; set(figH,'color','white'); set(figH, 'Position', [120 75 1500 500]);
subplot(211)
plot(t,fft_max); grid on;hold on;
plot([min(t) max(t)],[FFT_max FFT_max],'r')
ylabel('FFT Peak')

% Frequencies
subplot(212)
plot(t,frq_max,'*'); grid on; hold on
plot([min(t) max(t)],[FRQ_max FRQ_max],'r')
xlabel('Time [s]'); ylabel('Frequency [Hz]')

[path,fn,ext]=fileparts(filename);
suptitle(['File=' strrep(fn,'_','-') ext]);

%% Prepare output
out.fft_max=fft_max;
out.frq_max=frq_max;
out.FFT_max=FFT_max;
out.FRQ_max=FRQ_max;


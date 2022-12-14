function out = spectrogram(time,signal,dT,window)
% [t,frq,fft] = spectrogram(time,signal,dT,window)
% 
% Inputs:
%     time    - time signal
%     signal  - signal to process
%     dT      - timestep of the moving window
%     window  - window size in moving fft
%     
% Outputs:
%     t       - time matrix for moving fft
%     frq     - frq matrix for moving fft
%     fft     - fft matrix for moving fft

blocks=floor(time(end)/dT)-ceil(window/dT);
dt=time(2)-time(1);
for i=1:blocks
    i_start=find(time<dT*i, 1, 'last' );
    i_end=find(time<(dT*i+window),1,'last');
    [frq,fft(i,:)]=LAC.signal.fftcalc(time(i_start:i_end),signal(i_start:i_end),round(60/dt));
    t(i)=mean([time(i_start) time(i_end)]);
end

% Parse output
out.t=t;
out.frq=frq;
out.fft=fft;
function out=getPeak(time,signal,frq_min,frq_max)

dt=time(2)-time(1);
[FRQ,FFT]=LAC.signal.fftcalc(time,signal,round(60/dt));

FFT_sub=FFT(FRQ>frq_min&FRQ<frq_max);
FRQ_sub=FRQ(FRQ>frq_min&FRQ<frq_max);

[FFT_max, I_max]=max(FFT_sub);

out(1)=FFT_max; out(2)=FRQ_sub(I_max);
clc;clear;close all;
% Checking out the responses of different pole and zero placements

s = tf('s');

% Single poles/zeros

Tzerorhp = (s-1)/(1);
Tpolerhp = (1)/(s-1);
Tzerolhp = (s+1)/(1);
Tpolelhp = (1)/(s+1);

myfig(-1);
bode(Tpolerhp)
hold on
bode(Tpolelhp)
grid on
legend('T_polerhp', 'T_polelhp')

myfig(-1);
bode(Tzerorhp)
hold on
bode(Tzerolhp)
grid on
legend('T_zerorhp', 'T_zerolhp')

% double poles/zeros

Ttwozerorhp = ((1-1j-s)*(1+1j-s))/(1);
Ttwopolerhp = 1/((1-1j-s)*(1+1j-s));
Ttwozerolhp = ((1-1j+s)*(1+1j+s))/(1);
Ttwopolelhp = 1/((1-1j+s)*(1+1j+s));


myfig(-1);
bode(Ttwopolerhp)
hold on
bode(Ttwopolelhp)
grid on
legend('T_twopolerhp', 'T_twopolelhp')

myfig(-1);
bode(Ttwozerorhp)
hold on
bode(Ttwozerolhp)
grid on
legend('T_twozerorhp', 'T_twozerolhp')

myfig(-1);
step(Ttwopolerhp)


% double poles/zeros with full dampening

Ttwozerorhp = ((1-0-s)*(1+0-s))/(1);
Ttwopolerhp = 1/((1-0-s)*(1+0-s));
Ttwozerolhp = ((1-0+s)*(1+0+s))/(1);
Ttwopolelhp = 1/((1-0+s)*(1+0+s));


myfig(-1);
bode(Ttwopolerhp)
hold on
bode(Ttwopolelhp)
grid on
legend('T_twopolerhp', 'T_twopolelhp')

myfig(-1);
bode(Ttwozerorhp)
hold on
bode(Ttwozerolhp)
grid on
legend('T_twozerorhp', 'T_twozerolhp')


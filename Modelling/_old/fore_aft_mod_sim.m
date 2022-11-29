clc;clear;close all
% Simulation parameters
fs = 25;			% [Hz] - Sample freq. 
Ts = 1/fs;			% [s] - Sample time
Tsim = 1800;		% [s] - Simulation time
nt = 0:Ts:Tsim;		% - Simulation time index

% Constants from wtLin
frqHz1 = 0.0399;	% From ???? - For fore-aft model
mTwrTotal = 77743 + 82262 + 293382 + 3*36251; % From each part file
% mp.twr.mass = massTotal;
mTwr = mTwrTotal/100;
zeta = 0.02; % Predefined in comps.m file of fore-aft model definition

m = mTwr;
k = (2*pi*frqHz1)^2 * m;
b = 2*zeta*sqrt(k*m);



% constants
% k = 500.78;		% Spring coeff.
% b = 40.96;		% Damper coeff.
% m = 20;			% mass

Frot = 0;		% [N] - Simulating a constant rotor force

% Initial parameters
vy_0 = 0;
py_0 = -20;

vy(1) =  vy_0; py(1) = py_0;

for n = 1:(length(nt)-1)
	vy(n+1) = vy(n) + (Frot - b*vy(n) - k*py(n))/m * Ts;
	py(n+1) = py(n) + vy(n)*Ts ;
end

% Plotting both states
figure
plot(nt, py)
hold on
plot(nt, vy)
grid on
legend('py','vy')
hold off


%% Continuous time transfer function

% Parameters
% zeta = 0.7;
% feig = 1;
% 
% k = (2*pi*feig)^2 * m
% b = 2*zeta*sqrt(k*m)


s = tf('s');

TF = (1/m)/(s^2 + b/m * s + k/m)

dcgain = dcgain(TF)

p_c = pole(TF)
z_c = zero(TF)

figure
step(TF)
grid on

figure
margin(TF)
grid on


% Discretize system

TFd = c2d(TF, Ts, 'tustin')

figure
step(TF)
hold on
step(TFd)
hold off
legend('TF', 'TFd')

pzmap(TFd)

p_d = pole(TFd)
z_d = zero(TFd)


%% Varying zeta

frqHz1 = 0.0399;
mTwrTotal = 77743 + 82262 + 293382 + 3*36251;
mTwr = mTwrTotal/100;
zetaArray = [0.1:0.1:1];

m = mTwr;
k = (2*pi*frqHz1)^2 * m;
bArray = 2.*zetaArray.*sqrt(k*m)

legendArray = strcat("zeta = ", string(zetaArray))

s = tf('s');

myfig(-1);
for ii = 1:length(bArray)
	TF(ii) = (1/m)/(s^2 + bArray(ii)/m * s + k/m);
	bode(TF(ii))
	hold on
end
hold off
legend(legendArray)


%% Varying m

frqHz1 = 0.0399;
mTwrTotal = 77743 + 82262 + 293382 + 3*36251;
zeta = 0.02;

mArray = mTwrTotal.*[(1/2)^2 (1/2)^3 (1/2)^4 (1/2)^5 (1/2)^6];
kArray = (2*pi*frqHz1)^2 .* mArray;
bArray = 2*zeta.*sqrt(kArray.*mArray);

legendArray = strcat("m = ", string(mArray));

s = tf('s');

myfig(-1);
for ii = 1:length(bArray)
	TF(ii) = (1/mArray(ii))/(s^2 + bArray(ii)/mArray(ii) * s + kArray(ii)/mArray(ii));
	bode(TF(ii))
	hold on
end
hold off
legend(legendArray)


%% Varying frqHz1

frqHz1Array = [0.01:0.01:0.1];
mTwrTotal = 77743 + 82262 + 293382 + 3*36251;
zeta = 0.02;

m = mTwrTotal;
kArray = (2.*pi.*frqHz1Array).^2 .* m;
bArray = 2*zeta.*sqrt(kArray.*m);

legendArray = strcat("frqHz1 = ", string(frqHz1Array));

s = tf('s');

myfig(-1);
for ii = 1:length(bArray)
	TF(ii) = (1/m)/(s^2 + bArray(ii)/m * s + kArray(ii)/m);
	bode(TF(ii))
	hold on
end
hold off
legend(legendArray)


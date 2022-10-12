clc;clear;close all
% Simulation parameters
fs = 25;		% [Hz] - Sample freq. 
Ts = 1/fs;		% [s] - Sample time
Tsim = 10;		% [s] - Simulation time
nt = 0:Ts:Tsim; % - Simulation time index

% constants
k = 500.78;		% Spring coeff.
b = 40.96;		% Damper coeff.
m = 20;			% mass

Frot = 10;		% [N] - Simulating a constant rotor force

% Initial parameters
vy_0 = 0;
py_0 = -5;

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

% Continuous time transfer function

zeta = 0.7;
feig = 1;

k = (2*pi*feig)^2 * m
b = 2*zeta*sqrt(k*m)


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

% Discretize

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

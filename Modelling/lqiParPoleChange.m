clc;clear;
% close all;

load('wtLinScriptData.mat', 'Alqi', 'Bulqi', 'Bdlqi', 'Clqi', 'sysNoFLC2', ...
	'distIndex')



% -----------------
% | CHANGE THESE ->
% -----------------

% DEFAULT VALUES ->
% s_W = 1;		% [rpm] - Rotor speed
% s_py = 5;		% [m] - Fore-aft position
% s_vy = 1;		% [m] - Fore-aft velocity
% s_Wi = s_W*5;	% [rpm] Rotor speed integrator state
% 
% s_th = 5;		% [deg] - Pitch actuator
% <- DEFAULT VALUES

s_py = [5 2.5 1];				% [m] - Fore-aft position
s_vy = [0.5 0.25 0.1];			% [m] - Fore-aft velocity
s_W	 = [1 0.75 0.5]*2*pi/60;	% [rpm] - Rotor speed
s_Wi = [5 2.5 1]*2*pi/60;		% [rpm] Rotor speed integrator state

s_th = [1 2.5 5];				% [deg] - Pitch actuator

% -----------------
% <- CHANGE THESE |
% -----------------

% State weighting
var_py			= s_py.^2;					% Permitted variance of py in [m]
var_vy			= s_vy.^2;					% Permitted variance of vy in [m/s]
var_Omega		= (s_W .* (2*pi)./60).^2;	% Permitted variance of Omega in [rad/s]
var_OmegaInt	= (s_Wi .* (2*pi)./60).^2;	% rad/s -> rpm weight

% Input weighting
var_th = s_th.^2; % V2 tuning parameter
R = 1./var_th;

% Starting values of indexes:
qq = 1; ww = 1; ee = 1; rr = 1; tt = 3;

for nn = 1:5 % 5 = amount of variables (s_W, s_py.. etc.)
	for ii = 1:length(s_W)
		switch nn
			case 1
				qq = ii;
			case 2
				qq = 1;
				
				ww = ii;
			case 3
				qq = 1; ww = 1;
				
				ee = ii;
			case 4
				qq = 1; ww = 1; ee = 1;
				
				rr = ii;
			case 5
				qq = 1; ww = 1; ee = 1; rr = 1; 
				
				tt = ii;
		end
		
		Qlqi{nn,ii} = [1./var_py(qq)	0			0				0
						0			1./var_vy(ww)	0				0
						0			0			1./var_Omega(ee)		0
						0			0			0				1./var_OmegaInt(rr)];
		
		% Calculate LQI gains
		[Klqi{nn,ii}, S, P] = lqr(Alqi, Bulqi, Qlqi{nn,ii}, R(tt), 0);

		% Closed loop system with integrator:
		Acl_lqi{nn,ii} = Alqi-Bulqi*Klqi{nn,ii};

		% Creating the full closed loop LQR + integrator system
		sysLQI2{nn,ii} = ss(Acl_lqi{nn,ii}, Bdlqi, Clqi, 0);
		% Add missing integrator state name:
		tempStateNames = sysNoFLC2.StateName; tempStateNames{4} = 'W_i';
		sysLQI2{nn,ii}.StateName = tempStateNames;
		sysLQI2{nn,ii}.InputName = sysNoFLC2.InputName(distIndex); % Disturbance
		sysLQI2{nn,ii}.OutputName = sysNoFLC2.OutputName;
		
	end
end

% Plotting
% ---------------------
zoomEnabled = 0;

myfig(1, [0 0.70 1000 400]);
for nn = 1:2
	subplot(1,2,nn)
	pzmap(sysNoFLC2)
	hold on
	pzmap(sysLQI2{nn,1})
	pzmap(sysLQI2{nn,2})
	pzmap(sysLQI2{nn,3})
	if nn == 1
		for ii = 1:length(s_W)
			legstr(ii) = sprintf("max(py) = %.2f", s_py(ii));
		end
	elseif nn == 2
		for ii = 1:length(s_W)
			legstr(ii) = sprintf("max(vy) = %.2f", s_vy(ii));
		end
	end
	if zoomEnabled; xlim([-0.21 0.01]); ylim([-0.01 0.26]); end
	legend(['FLC PI', legstr], 'Location','northwest')
	hold off
end

myfig(2, [0 0.25 1000 400]);
for nn = 3:4
	subplot(1,2,nn-2)
	pzmap(sysNoFLC2)
	hold on
	pzmap(sysLQI2{nn,1})
	pzmap(sysLQI2{nn,2})
	pzmap(sysLQI2{nn,3})
	if nn == 3
		for ii = 1:length(s_W)
			legstr(ii) = sprintf("max(W) = %.2f [rpm]", s_W(ii));
		end
	elseif nn == 4
		for ii = 1:length(s_W)
			legstr(ii) = sprintf("max(Wi) = %.2f [rpm]", s_Wi(ii));
		end
	end
	if zoomEnabled; xlim([-1.05 0.01]); ylim([-0.01 0.26]); end
	legend(['FLC PI', legstr], 'Location','northwest')
	hold off
end

myfig(3, [0.8 0.5 500 400]);
pzmap(sysNoFLC2)
nn = 5;
hold on
pzmap(sysLQI2{nn,1})
pzmap(sysLQI2{nn,2})
pzmap(sysLQI2{nn,3})
for ii = 1:length(s_W)
	legstr(ii) = sprintf("max(thRef) = %.2f", s_th(ii));
end
if zoomEnabled; xlim([-1.05 0.01]); ylim([-0.01 0.26]); end
legend(['FLC PI', legstr], 'Location','northwest')
hold

% myfig(10);
% step(sysLQI2{4,1})
% hold on
% step(sysLQI2{4,2})
% step(sysLQI2{4,3})
% legend(legstr, 'Location','northwest')

myfig(11);
bode(sysLQI2{2,2})
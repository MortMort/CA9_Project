clc;clear;
close all;

load('wtLinScriptData.mat', 'Alqi', 'Bulqi', 'Bdlqi', 'Clqi', 'sys', ...
	'sysNoFLC2', 'distIndex')



% -----------------
% | CHANGE THESE ->
% -----------------

% DEFAULT VALUES ->
s_pydef = 5;		% [m] - Fore-aft position
s_vydef = 1;		% [m] - Fore-aft velocity
s_Wdef = 1;			% [rpm] - Rotor speed
s_Widef = s_Wdef*5;	% [rpm] Rotor speed integrator state

s_thdef = 5;		% [deg] - Pitch actuator
% <- DEFAULT VALUES

s_py = [s_pydef s_pydef*0.5 s_pydef*0.25];		% [m] - Fore-aft position
s_vy = [s_vydef s_vydef*0.5 s_vydef*0.25];		% [m] - Fore-aft velocity
s_W	 = [s_Wdef	s_Wdef*0.5  s_Wdef*0.25];		% [rpm] - Rotor speed
s_Wi = [s_Widef s_Widef*0.5 s_Widef*0.25];		% [rpm] Rotor speed integrator state

s_th = [s_thdef*0.2 s_thdef*0.5 s_thdef];		% [deg] - Pitch actuator

sArray = [s_py;s_vy;s_W;s_Wi;s_th];
% -----------------
% <- CHANGE THESE |
% -----------------

% State weighting
var_py			= s_py.^2;					% Permitted variance of py in [m]
var_vy			= s_vy.^2;					% Permitted variance of vy in [m/s]
var_Omega		= (s_W .* (2*pi)/60).^2;	% Permitted variance of Omega in [rad/s]
var_OmegaInt	= (s_Wi .* (2*pi)/60).^2;	% rad/s -> rpm weight

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

% Default figure dimensions and location based on # of plots in subplot:
% figSize.one =	[1 0.25 700 300];
% figSize.two =	[1 0.25 700 400];
% figSize.three = [1 0.25 700 550];
% figSize.four =	[1 0.25 700 670];

% fontSize.leg = 11;
% fontSize.legSmall = 9;
% fontSize.title = 13;
% fontSize.label = 11;

zoomEnabled = 0;

% set(groot, 'defaultAxesTickLabelInterpreter','latex');
% set(groot, 'defaultAxesTickLabelInterpreter','latex');
% set(groot, 'defaultLegendInterpreter','latex');
% set(groot, 'defaultTextInterpreter','latex');
% set(groot, 'defaultBubblelegendInterpreter', 'latex')
% set(groot, 'defaultPolaraxesTickLabelInterpreter', 'latex')
% set(groot, 'defaultTextInterpreter', 'latex')

% Change the default font size of figures:
% set(groot,'defaultAxesFontSize', 10)		% Default is 10
% set(groot, 'defaultAxesLabelFontSize', 10);	% Default is ??
% set(groot, 'defaultLegendFontSize', 9);	% Default is 9

% set(groot,'defaultAxesTitleFontSizeMultiplier', 1.1) % 1.1 is default


% See all possible values that can be set:
% get(groot, 'factory')
% See the values whoose defaults have been changed:
% get(groot, 'default') 

% Set grid to be ON as default for this matlab session
set(groot,'DefaultAxesXGrid','on')
set(groot,'DefaultAxesYGrid','on')
% Not working for some reason on pzmaps and steps


% Extract default color codes for figure plots
defColors = get(groot,'defaultAxesColorOrder');
defCol.blue = defColors(1,:);
defCol.red = defColors(2,:);
defCol.yellow = defColors(3,:);
defCol.purple = defColors(4,:);

% Initialize figure array and figure name array
figArray = [];
figNameArray = [];

variableArray = ["py", "vy", "W", "Wi", "theta"];

%% Test section

xlimCell = {0; 0; [-2.2 0.05]; 0; 0};
ylimCell = {0; 0; [-0.27 0.27]; 0; 0};

close all

% Each cell row is an arrow, each cell column from 1 -> 5 represents each
% figure plot. 0 in a cokumn means that that plot does not have an arrow.
arrowCell = {0, [0.85 0.84; 0.85 0.73], 0, 0, [0.85 0.85; 0.87 0.83]
			0, [0.78 0.82; 0.53 0.53], 0, 0, [0.76 0.6; 1-0.66 1-0.67]
			0, [0.6 0.2; 0.53 0.53], [0.7 0.2; 0.53 0.53], 0, [0.6 0.62; 1-0.67 0.49]
			0, [0.85 0.84; 1-0.86 1-0.73], 0, 0, [0.76 0.62; 0.66 0.67]
			0, 0, 0, 0, [0.62 0.22; 0.67 0.52]
			0, 0, 0, 0, [0.85 0.85; 1-0.88 1-0.84]};


% Box
boxCell = {0, 0, [.8 .48 .1 .4], 0, 0};

% Text
textCell = {0, 0, [-0.55 0.14], 0, 0};

% Pole-zero maps
for nn = 1:5
	figNo = nn;
	f = myfig(figNo, [0 0.70 540 450]);
	pzmap(sysNoFLC2)
	hold on
	pzmap(sysLQI2{nn,1})
	pzmap(sysLQI2{nn,2})
	pzmap(sysLQI2{nn,3})
	a = findobj(gca, 'type', 'line');
	for i = 1:length(a)
    	set(a(i), 'markersize', 8);	% change marker size
    	set(a(i), 'linewidth', 1.5); % change linewidth
	end
	% Add arrows
	for ii = 1:length([arrowCell{:,1}])
		if arrowCell{ii,nn} > 0
			annotation('arrow', arrowCell{ii,nn}(1,:), arrowCell{ii,nn}(2,:))
		end
	end
	% Add boxes
	if boxCell{nn} > 0
		annotation('rectangle',boxCell{nn}, 'LineStyle', '--')
	end
	% Add text
	if textCell{nn} ~= 0
		text(textCell{nn}(1), textCell{nn}(2),'Zoom area')
	end
	% Create legends:
	for ii = 1:length(s_W)
		legStr(ii) = sprintf(strcat('max(', string(variableArray(nn)), ') = %.2f'), sArray(nn,ii));
	end
	legend(['Uncontrolled', legStr], 'Location','northwest')
	title(strcat("Pole-zero map with varying max(", variableArray(nn), ")"))
	hold off
	if xlimCell{nn} ~= 0
		xlim(xlimCell{nn})
	end
	if ylimCell{nn} ~= 0
		ylim(ylimCell{nn})
	end
	figArray = [figArray f];
	figNameArray = [figNameArray strcat(string(0), string(figNo), '_pzmap_', string(variableArray(nn)))];
end

%% Test section 

% close all

xlimCell = {0; [-0.225 0.01]; [-0.225 0.01]; 0; 0};
ylimCell = {0; [-0.01 0.26]; [-0.01 0.26]; 0; 0};

% Zoom

arrowCell = {0, 0, [0.66 0.8; 0.75 0.83], 0, 0
			0, 0, 0, 0, 0
			0, 0, [0.18 0.71; 0.16 0.16], 0, 0};

for nn = 1:5
	figNo = nn + 10;
	f = myfig(figNo, [0.4 0.70 540 450]);
	pzmap(sysNoFLC2)
	hold on
	pzmap(sysLQI2{nn,1})
	pzmap(sysLQI2{nn,2})
	pzmap(sysLQI2{nn,3})
	a = findobj(gca,'type','line');
	for i = 1:length(a)
    	set(a(i),'markersize',8); %change marker size
    	set(a(i), 'linewidth',1.5);  %change linewidth
	end
	% Add arrows
	for ii = 1:length([arrowCell{:,1}])
		if arrowCell{ii,nn} > 0
			annotation('arrow', arrowCell{ii,nn}(1,:), arrowCell{ii,nn}(2,:))
		end
	end
	
	% Create legends:
	for ii = 1:length(s_W)
		legStr(ii) = sprintf(strcat('max(', string(variableArray(nn)), ') = %.2f'), sArray(nn,ii));
	end
	legend(['Uncontrolled', legStr], 'Location','northwest')
	title(strcat("Pole-zero map with varying max(", variableArray(nn), ") - Zoomed"))
	hold off
	if xlimCell{nn} ~= 0
		xlim(xlimCell{nn})
	end
	if ylimCell{nn} ~= 0
		ylim(ylimCell{nn})
	end
	figArray = [figArray f];
	figNameArray = [figNameArray strcat(string(figNo), '_pzmapzoom_', string(variableArray(nn)))];
end

%% Steps
ylabelArray = ["Position [m]", "Velocity [m/s]", "Angular velocity [rad/s]"]

for nn = 1:5
	% Pull step data:
	for ii = 1:3
		[y{ii}, tOut{ii}] = step(sysLQI2{nn,ii}, 100); % Step for 100 seconds
	end
	
	% Plot the steps
	figNo = nn+100;
	f = myfig(figNo, [0.7 0.70 650 450]);
	for qq = 1:3
		subplot(3,1,qq)
		plot(tOut{1}, y{1}(:,qq), 'Color', defCol.red, 'linewidth',1.3)
		hold on
		plot(tOut{2}, y{2}(:,qq), 'Color', defCol.yellow, 'linewidth',1.3)
		plot(tOut{3}, y{3}(:,qq), 'Color', defCol.purple, 'linewidth',1.3)
		xlim([0 100])
		% Set title on first subplot
		if qq == 1, title(strcat("Disturbance step response with varying max(", variableArray(nn), ")")), end
		% Set legend and xlabel on last subplot
		if qq == 3 
			% Create legends:
			for ii = 1:length(s_W)
				legStr(ii) = sprintf(strcat('max(', string(variableArray(nn)), ') = %.2f'), sArray(nn,ii));
			end
			legend(legStr)
			xlabel('Time [s]')
		end
		ylabel(ylabelArray(qq))
	end
	
	hold off
% 	if xlimCell{nn} ~= 0
% 		xlim(xlimCell{nn})
% 	end
% 	if ylimCell{nn} ~= 0
% 		ylim(ylimCell{nn})
% 	end
	grid on
	figArray = [figArray f];
	figNameArray = [figNameArray strcat(string(figNo), '_step_', string(variableArray(nn)))];
end


%% Bode
% for nn = 1:5
% 	figNo = nn+200;
% 	f = myfig(figNo, [0.7 0.70 600 500]);
% 	bode(sysLQI2{nn,1})
% 	hold on
% 	bode(sysLQI2{nn,2})
% 	bode(sysLQI2{nn,3})
% 	% Create legends:
% 	for ii = 1:length(s_W)
% 		legStr(ii) = sprintf(strcat('max(', string(variableArray(nn)), ') = %.2f'), sArray(nn,ii));
% 	end
% 	legend(legStr, 'Location','northeast')
% 	title(strcat("Bode plot with varying max(", variableArray(nn), ")"))
% 	hold off
% % 	if xlimCell{nn} ~= 0
% % 		xlim(xlimCell{nn})
% % 	end
% % 	if ylimCell{nn} ~= 0
% % 		ylim(ylimCell{nn})
% % 	end
% 	grid on
% 	figArray = [figArray f];
% 	figNameArray = [figNameArray strcat(string(figNo), '_bode_', string(variableArray(nn)))];
% end



%% W and Wi
% myfig(2, [0 0.25 1000 400]);
% for nn = 3:4
% 	subplot(1,2,nn-2)
% 	pzmap(sysNoFLC2)
% 	hold on
% 	pzmap(sysLQI2{nn,1})
% 	pzmap(sysLQI2{nn,2})
% 	pzmap(sysLQI2{nn,3})
% 	if nn == 3
% 		for ii = 1:length(s_W)
% 			legstr(ii) = sprintf("max(W) = %.2f [rpm]", s_W(ii));
% 		end
% 	elseif nn == 4
% 		for ii = 1:length(s_W)
% 			legstr(ii) = sprintf("max(Wi) = %.2f [rpm]", s_Wi(ii));
% 		end
% 	end
% 	if zoomEnabled; xlim([-1.05 0.01]); ylim([-0.01 0.26]); end
% 	legend(['Uncontrolled', legstr], 'Location','northwest')
% 	hold off
% end
% 
% % Theta
% myfig(3, [0.8 0.5 500 400]);
% pzmap(sysNoFLC2)
% nn = 5;
% hold on
% pzmap(sysLQI2{nn,1})
% pzmap(sysLQI2{nn,2})
% pzmap(sysLQI2{nn,3})
% for ii = 1:length(s_W)
% 	legstr(ii) = sprintf("max(thRef) = %.2f", s_th(ii));
% end
% if zoomEnabled; xlim([-1.05 0.01]); ylim([-0.01 0.26]); end
% legend(['Uncontrolled', legstr], 'Location','northwest')
% hold

% myfig(10);
% step(sysLQI2{4,1})
% hold on
% step(sysLQI2{4,2})
% step(sysLQI2{4,3})
% legend(legstr, 'Location','northwest')

% myfig(10, [0 0.70 1000 400]);
% bode(sysLQI2{1,1})
% hold on
% bode(sysLQI2{1,2})
% bode(sysLQI2{1,3})
% for ii = 1:length(s_W)
% 	legstr(ii) = sprintf("max(py) = %.2f", s_py(ii));
% end
% % 	if zoomEnabled; xlim([-0.21 0.01]); ylim([-0.01 0.26]); end
% legend(legstr, 'Location','northwest')


% myfig(11, [0 0.70 1000 400]);
% step(sysLQI2{1,1})
% hold on
% step(sysLQI2{1,2})
% step(sysLQI2{1,3})
% for ii = 1:length(s_W)
% 	legstr(ii) = sprintf("max(py) = %.2f", s_py(ii));
% end
% % 	if zoomEnabled; xlim([-0.21 0.01]); ylim([-0.01 0.26]); end
% legend(legstr, 'Location','northwest')


%% Export figures
% ---------------------------------
if ispc
	% Path to folder on windows
	figSaveDir = "c:\Users\Mrotr\Git\Repos\CA9_Writings\Graphics"; % Windows type path
else
	% Set path to git folder on mac
	figSaveDir = "/Users/martin/Documents/Git/Repos/CA9_Writings/Graphics"; % Windows type path
end

exportFileType = ".png";
figNameArray = strcat(figNameArray, exportFileType);

% figSaveDir = "H:/Offshore_TEMP/USERS/MROTR/wtLinWork"; % Macos type path
createNewFolder = 1; % Folder name to save figures:
resolution = 400;
myfigexport(figSaveDir, figArray, figNameArray, createNewFolder, "LQI pole zero", resolution)

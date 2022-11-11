selectedSimSetup = 2;

if selectedSimSetup == 1
	wantedSims = [1];
elseif selectedSimSetup == 2
	wantedSims = [1 2];
elseif selectedSimSetup == 3
	wantedSims = [1 2 3];
elseif selectedSimSetup == 4
	wantedSims = [1 2 3 4];
elseif selectedSimSetup == 5
	wantedSims = [5 6 7 8];
elseif selectedSimSetup == 6
	wantedSims = [1 2 3 4 5];
% elseif selectedSimSetup == 7
% 	wantedSims = [1 2 3 4 5 6 7];
% elseif selectedSimSetup == 8
% 	wantedSims = [1 2 3 4 5 6 7 8];
end

xLimDef1 = [0 600];
xLimFftDef1 = [0 0.6];
yLimDef1 = [0 1];

f = myfigplot(100, [senIdx.Vhfree, senIdx.Power, senIdx.GenMom, senIdx.OmGen], wantedSims, ...
	Xdata, Ydata, titleArray, ylabelArray, simNames, 1, xLimDef1, 0, 1);

figArray = [figArray f];
figNameArray = [figNameArray strcat(setupPrefix, "vhfree_power_genmom_omgen.png")];


f = myfigplot(101, [senIdx.UyKF, senIdx.OmGen, senIdx.Pi1], wantedSims, Xdata, ...
	Ydata, titleArray, ylabelArray, simNames, 1, xLimDef1, 0, 1);
figArray = [figArray f];
figNameArray = [figNameArray strcat(setupPrefix, "uykf_omgen_pi1.png")];


% Zoomed
f = myfigplot(102, [senIdx.Vhfree, senIdx.Power, senIdx.GenMom, senIdx.OmGen], wantedSims, ...
	Xdata, Ydata, titleArray, ylabelArray, simNames, 1, [0 120], 0, 1);

figArray = [figArray f];
figNameArray = [figNameArray strcat(setupPrefix, "vhfree_power_genmom_omgen_zoom.png")];


% Zoomed
f = myfigplot(103, [senIdx.UyKF, senIdx.OmGen, senIdx.Pi1], wantedSims, Xdata, ...
	Ydata, titleArray, ylabelArray, simNames, 1, [0 120], 0, 1);
figArray = [figArray f];
figNameArray = [figNameArray strcat(setupPrefix, "uykf_omgen_pi1_zoom.png")];


% Plotting FFTs
% ---------------
% Changes Ydata -> sensorDataFFT, Xdata -> nf, 1 -> 0

% x and y translation position and roll and pitch angle
% f = myfigplot(200, [senIdx.xKF senIdx.yKF], wantedSims, nf, sensorDataFFT, ...
% 	titleArray, ylabelArray, simNames, 0, xLimFftDef1, [0 1]);
% figArray = [figArray f];
% figNameArray = [figNameArray strcat(setupPrefix, "xPosyPosFFT.png")];

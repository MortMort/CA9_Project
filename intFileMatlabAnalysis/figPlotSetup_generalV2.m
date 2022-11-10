selectedSimSetup = 3;

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

% Free wind, blade pitch, Rotor speed, Generator torque
f = myfigplot(100, [senIdx.Vhfree senIdx.Pi1 senIdx.Omega senIdx.GenMom], wantedSims, Xdata, Ydata, titleArray, ylabelArray, simNames, 1, xLimDef1, 0);
figArray = [figArray f];
figNameArray = [figNameArray strcat(setupPrefix, "VfreeToMgen.png")];


% x and y translation position and roll and pitch angle
f = myfigplot(101, [senIdx.xKF senIdx.yKF senIdx.AlyKF senIdx.AlxKF], wantedSims, Xdata, Ydata, titleArray, ylabelArray, simNames, 1, xLimDef1, 0);

figArray = [figArray f];
figNameArray = [figNameArray strcat(setupPrefix, "xPosToPitchAng.png")];

% x and y translation velocity and roll and pitch angular velocity
f = myfigplot(102, [senIdx.UxKF senIdx.UyKF senIdx.OMyKF senIdx.OMxKF], wantedSims, Xdata, Ydata, titleArray, ylabelArray, simNames, 1, xLimDef1, 0);
figArray = [figArray f];
figNameArray = [figNameArray strcat(setupPrefix, "xVelToPitchAngVel.png")];



% Plotting FFTs
% ---------------
% Changes Ydata -> sensorDataFFT, Xdata -> nf, 1 -> 0

% x and y translation position and roll and pitch angle
f = myfigplot(200, [senIdx.xKF senIdx.yKF], wantedSims, nf, sensorDataFFT, titleArray, ylabelArray, simNames, 0, xLimFftDef1, [0 1]);
figArray = [figArray f];
figNameArray = [figNameArray strcat(setupPrefix, "xPosyPosFFT.png")];

% x and y translation position and roll and pitch angle
f = myfigplot(201, [senIdx.AlyKF senIdx.AlxKF], wantedSims, nf, sensorDataFFT, titleArray, ylabelArray, simNames, 0, xLimFftDef1, [0 0.05]);
figArray = [figArray f];
figNameArray = [figNameArray strcat(setupPrefix, "RollPitchAngFFT.png")];



% x and y translation velocity and roll and pitch angular velocity
f = myfigplot(202, [senIdx.UxKF senIdx.UyKF], wantedSims, nf, sensorDataFFT, titleArray, ylabelArray, simNames, 0, xLimFftDef1, [0 0.5]);
figArray = [figArray f];
figNameArray = [figNameArray strcat(setupPrefix, "xVelyVelFFT.png")];

f = myfigplot(203, [senIdx.OMyKF senIdx.OMxKF], wantedSims, nf, sensorDataFFT, titleArray, ylabelArray, simNames, 0, xLimFftDef1, [0 0.01]);
figArray = [figArray f];
figNameArray = [figNameArray strcat(setupPrefix, "RollPitchAngVelFFT.png")];

% Rotor speed (Omega)
f = myfigplot(204, [senIdx.Omega], wantedSims, nf, sensorDataFFT, titleArray, ylabelArray, simNames, 0, xLimFftDef1, [0 0.5]);
figArray = [figArray f];
figNameArray = [figNameArray strcat(setupPrefix, "OmegaFFT.png")];


% 
f = myfigplot(205, [senIdx.PSI senIdx.OMyKF senIdx.OMxKF], wantedSims, nf, sensorDataFFT, titleArray, ylabelArray, simNames, 0, xLimFftDef1, [0 50]);
figArray = [figArray f];
figNameArray = [figNameArray strcat(setupPrefix, "PSIxVelyVelFFT.png")];
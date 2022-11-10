% This is the figure plotting setup for the tj00 test

% Select simulation setup
selectedSimSetup = 6;

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
% wantedSims = [1 2 3 4];

% Free wind, blade pitch, Rotor speed, Generator torque
f = myfigplot(100, [1 3 7 8], wantedSims, Xdata, sensorData, titleArray, ylabelArray, simNames, 1, [1000 1100], 0);
figArray = [figArray f];
figNameArray = [figNameArray strcat(setupPrefix, "VfreeToMgen.png")];


% x and y translation position and roll and pitch angle
f = myfigplot(101, [10 11 14 13], wantedSims, Xdata, sensorData, titleArray, ylabelArray, simNames, 1, [1000 1100], 0);

figArray = [figArray f];
figNameArray = [figNameArray strcat(setupPrefix, "xPosToPitchAng.png")];

% x and y translation velocity and roll and pitch angular velocity
f = myfigplot(102, [16 17 20 19], wantedSims, Xdata, sensorData, titleArray, ylabelArray, simNames, 1, [1000 1100], 0);
figArray = [figArray f];
figNameArray = [figNameArray strcat(setupPrefix, "xVelToPitchAngVel.png")];


% Plotting FFTs
% ---------------
% Changes sensorData -> sensorDataFFT, Xdata -> nf, 1 -> 0

% x and y translation position and roll and pitch angle
f = myfigplot(202, [10 11], wantedSims, nf, sensorDataFFT, titleArray, ylabelArray, simNames, 0, [0 0.1], [0 1]);
% f = myfigplot(202, [10 11 14 13], wantedSims], nf, sensorDataFFT, titleArray, ylabelArray, simNames, 0, 0, 0);
figArray = [figArray f];
figNameArray = [figNameArray strcat(setupPrefix, "xPosyPosFFT.png")];

% x and y translation position and roll and pitch angle
f = myfigplot(203, [14 13], wantedSims, nf, sensorDataFFT, titleArray, ylabelArray, simNames, 0, [0 0.1], [0 0.05]);
% f = myfigplot(202, [10 11 14 13], wantedSims], nf, sensorDataFFT, titleArray, ylabelArray, simNames, 0, 0, 0);

figArray = [figArray f];
figNameArray = [figNameArray strcat(setupPrefix, "RollPitchAngFFT.png")];



% x and y translation velocity and roll and pitch angular velocity
% f = myfigplot(203, [16 17 20 19], wantedSims, nf, sensorDataFFT, titleArray, ylabelArray, simNames, 0, 0, 0);
f = myfigplot(204, [16 17], wantedSims, nf, sensorDataFFT, titleArray, ylabelArray, simNames, 0, [0 0.1], [0 0.5]);
figArray = [figArray f];
figNameArray = [figNameArray strcat(setupPrefix, "xVelyVelFFT.png")];

f = myfigplot(205, [20 19], wantedSims, nf, sensorDataFFT, titleArray, ylabelArray, simNames, 0, [0 0.1], [0 0.01]);
figArray = [figArray f];
figNameArray = [figNameArray strcat(setupPrefix, "RollPitchAngVelFFT.png")];

% Rotor speed (Omega)
f = myfigplot(206, [7], wantedSims, nf, sensorDataFFT, titleArray, ylabelArray, simNames, 0, [0 0.1], [0 0.5]);
figArray = [figArray f];
figNameArray = [figNameArray strcat(setupPrefix, "OmegaFFT.png")];

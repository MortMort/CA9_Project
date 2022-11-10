% The below vector contains the IDs of the sensors which are of interest.
% If the # of sensors prepped for simulation is changed then these IDs maybe will
% change as well


% Sensor indexes are connected to their name. If anohter sensor setup is
% used these indexes might change and they would need to be changed here
% accordingly!
senIdx.Vhfree = 1;
senIdx.Vhub = 3;
senIdx.Pi1 = 7;
senIdx.Pi2 = 10;
senIdx.Pi3 = 13;
senIdx.PSI = 16;
senIdx.Omega = 17;
senIdx.Power = 19;
senIdx.GenMom = 21;
senIdx.xKF = 109;
senIdx.yKF = 110;
senIdx.zKF = 111;
senIdx.AlxKF = 112;
senIdx.AlyKF = 113;
senIdx.AlzKF = 114;
senIdx.UxKF = 115;
senIdx.UyKF = 116;
senIdx.UzKF = 117;
senIdx.OMxKF = 118;
senIdx.OMyKF = 119;
senIdx.OMzKF = 120;
senIdx.OMxK = 121;
senIdx.OMyK = 122;
senIdx.OMzK = 123;
senIdx.OMPxK = 124;
senIdx.OMPyK = 125;
senIdx.OMPzK = 126;

senIdx.pnt206 = 165; % (prn#TP_GeneratorSpeedReference)
senIdx.pnt413 = 168; % (prn#TP_SC_GenSpdRef)
senIdx.pfo017 = 174; % (prf#PowerReference)
senIdx.pft032 = 179; % (prf#TP_FATD_ColPitchPosRefOffset)
senIdx.pft105 = 204; % (prf#TP_FLC_PitchPosRef)
senIdx.pft229 = 207; % (prf#TP_TestSine_GenSpdRef)

% Converts all the indexes from the above made structs into an array
% containing the structs.
sensorIDs = cell2mat(struct2cell(senIdx));
		

% Sensor names. Used for legends when plotting
legArray(sensorIDs) = ["Vfree", "Vhub", "Pi1", "Pi2", "Pi3", "PSI", "Omega", "Power", "GenMom", "xKF", ...
	"yKF", "zKF", "AlxKF", "AlyKF", "AlzKF", "UxKF", "UyKF", "UzKF","OMxKF", ...
	"OMyKF", "OMzKF", "AxKF", "AyKF", "AzKF","OMPxKF", "OMPyKF", "OMPzKF", ...
	"pnt206", "pnt413", "pfo017", "pft032", "pft105", "pft229"];

% Title names. Used for titles when plotting
titleArray(sensorIDs) = ["Free wind speed", "Hub wind speed", "Blade pitch angle 1", "Blade pitch angle 2", ...
	"Blade pitch angle 3", "Rotor azimuth", "Rotor angular velocity", "Power", "Generator torque"...
	"x-axis translation position", "y-axis translation position", "z-axis translation position", ...
	"Tower Pitch angle", "Tower Roll angle", "Tower Yaw angle??? Or?", ...
	"x-axis translational velocity", "y-axis translational velocity", "z-axis translational velocity", ...
	"Tower Pitch speed", "Tower Roll speed", "Tower Yaw speed??? Or?", ...
	"x-axis translational acceleration", "y-axis translational acceleration", "z-axis translational acceleration", ...
	"Tower Pitch angular acceleration", "Tower Roll angular acceleration", "Tower Yaw angular acceleration???", ...
	"Generator speed reference", "Generator speed reference", "Power reference", ...
	"FATD Collective pitch position reference offset", "Pitch position reference", ...
	"Test sine generator speed reference"];

% ylabels. Used for ylabels when plotting
units.vel		=	"Velocity [m/s]";
units.angDeg	= "Angle [deg]";
units.angRad	= "Angle [rad]";
units.angVel	= "Angular Velocity [rad/s]";
units.angAcc	= "Angular Acceleration [rad/s^2]";
units.acc		= "Acceleration [m/s^2]";
units.T			= "Torque [Nm]";
units.pos		= "Position [m]";
units.pow		= "Power [W]";


ylabelArray(sensorIDs) = [units.vel, units.vel, units.angDeg, units.angDeg, units.angDeg, ...
			units.angDeg, units.angVel, units.pow units.T, units.pos, units.pos, units.pos, ...
			units.angRad, units.angRad, units.angRad, ...
			units.vel, units.vel, units.vel, ...
			units.angVel, units.angVel, units.angVel, ...
			units.acc, units.acc, units.acc, ...
			units.angAcc, units.angAcc, units.angAcc, ...
			units.angVel, units.angVel, units.pow, units.angDeg, units.angDeg, ...
			units.angVel];
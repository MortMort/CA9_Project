
function Filename = PitchParam2CtrlAndVTSparam(Hydr,varargin)
% Filename = PitchParam2CtrlAndVTSparam(Hydr,varargin)
% Pitch Parameter Translate for VTS and Control Par 
% NIWJO JUN 2019
%
% Required input
%   Download newest pitch parameter file from DMS 0041-2425 and save it in
%   current folder.
%   parameterfile   = 'w:\ToolsDevelopment\vtsInputTrans\PIT\Pitch Geometry Parameters.xlsx';
%   Use the following script to make the Hydr structure
%   Hydr            = PitchGeometry.collectPitchParameters(parameterfile);
%   or write the parameters manually from DMS 0041-2425
%   Hydr.name = 'VidarF3';
%   Hydr.R          			= 0.8;              % Crank Radius [m]
%   Hydr.Xa         			= 0.64;             % Suspension X pos [m]
%   Hydr.Ya         			= 2.3;              % Suspension Y pos [m]
%   Hydr.k          			= 1.810;            % Static part of cylinder length [m] (ABmin)
%   Hydr.Pdz        			= -5.2719*pi/180;   % TC shift angle [rad]
%   Hydr.x_stroke   			= 1.22;             % Stroke length [m]
%   Hydr.d_rod      			= 125e-3;           % Rod diameter [m]
%   Hydr.d_piston   			= 200e-3;           % Piston diameter [m]
%   Hydr.effectiveVolAcc 		= 70e-3; 			% Accumulator - eff. volumen [m3] 
%   Hydr.preChargePressureAcc = 110e5; 			% Pre-charge pressure [Pa]
%   Hydr.Orifice1_Diameter 	= 0;				% Safety Pitch Orifice1 [mm]
%   Hydr.Orifice2_Diameter 	= 5; 				% Safety Pitch Orifice2 [mm]
%   Hydr.PitchSpeedHigh 		= 3.3427; 			% Safety Pitch Speed High [deg/s]
%   Hydr.PitchSpeedLow 		= 0.7577; 			% Safety Pitch Speed Low [deg/s]
%   Hydr.PiMax 				= 95; 				% Maximum pitching angle before lock [deg]
%
% Optional Inputs
%  - plotfig, eg PitchParam2CtrlAndVTSparam(Hydr,'plotfig', 1) 
%  - outputfolder, eg PitchParam2CtrlAndVTSparam(Hydr,'outputfolder', path) 
%
% Run script as
% Example 1
% Hydr = LAC.componentgroups.PIT.collectPitchParameters('Pitch Geometry Parameters.xlsx');
% PitchParam2CtrlAndVTSparam(Hydr)
%
% Example 2
% Hydr = LAC.componentgroups.PIT.collectPitchParameters('Pitch Geometry Parameters.xlsx');
% path = 'w:\ToolsDevelopment\vtsInputTrans\PIT\'
% PitchParam2CtrlAndVTSparam(Hydr,'outputfolder', path,'plotfig', 1)

%% Input handle
outputfolder = pwd;
plotfig = 0;
while ~isempty(varargin)
    switch lower(varargin{1})
        case 'plotfig'
            plotfig            = varargin{2};
            varargin(1:2) = [];
        case 'outputfolder'
            outputfolder            = varargin{2};
            varargin(1:2) = [];
        otherwise
            error(['Unexpected option: ' varargin{1}])
    end
end
%Filename = fullfile(outputfolder,['pitch_translate_' Hydr.name '_' regexprep(char(date),{'-'},{''}) '.txt']);
Filename = fullfile(outputfolder,['pitch_translate_' Hydr.name '.txt']);
fid             = fopen(Filename,'wt');

% Write out input parameters
fprintf(fid, '\n------=========  Pitch Parameters Translate for VTS and Control =========------\n');
fprintf(fid, ' %s\n',[Hydr.name '_' regexprep(char(date),{'-'},{''})]);
fprintf(fid, '\n------=========  Input Pitch Parameters =========------\n\n');
fprintf(fid, 'R                     = %f\n', Hydr.R);
fprintf(fid, 'Ya                    = %f\n', Hydr.Ya);
fprintf(fid, 'Xa                    = %f\n', Hydr.Xa);
fprintf(fid, 'x_stroke              = %f\n', Hydr.x_stroke);
fprintf(fid, 'k                     = %f\n', Hydr.k);
fprintf(fid, 'Pdz                   = %f\n', Hydr.Pdz);
fprintf(fid, 'd_rod                 = %f\n', Hydr.d_rod);
fprintf(fid, 'd_piston              = %f\n', Hydr.d_piston);
fprintf(fid, 'effectiveVolAcc       = %f\n', Hydr.effectiveVolAcc);
fprintf(fid, 'preChargePressureAcc  = %f\n', Hydr.preChargePressureAcc);
fprintf(fid, 'Orifice1_Diameter     = %f\n', Hydr.Orifice1_Diameter);
fprintf(fid, 'Orifice2_Diameter     = %f\n', Hydr.Orifice2_Diameter);
fprintf(fid, 'PitchSpeedHigh        = %f\n', Hydr.PitchSpeedHigh);
fprintf(fid, 'PitchSpeedLow         = %f\n', Hydr.PitchSpeedLow);

% Control inputs
fprintf(fid, '\n------=========  Control Pitch Parameters =========------\n\n');
fprintf(fid, 'Px_PiSP_PitchCylinderAreaPositive = %f\n', Hydr.Aregen);
fprintf(fid, 'Px_PiSP_PitchCylinderAreaNegative = %f\n', Hydr.Ar);
fprintf(fid, 'Px_PiSP_PitchCylinderAreaBoost    = %f\n', Hydr.Ap);
fprintf(fid, 'Px_PiSP_PistonMaxPosition         = %f\n', Hydr.x_stroke);
fprintf(fid, 'Px_PitchGeometry_Switch           = %f\n', 0);
fprintf(fid, 'Px_MinPistonPos                   = %f\n', Hydr.k);
fprintf(fid, 'Px_ZeroPosAlfaAngle               = %f\n', Hydr.alpha_min);
fprintf(fid, 'Px_PitchMovementRadius            = %f\n', Hydr.R);
fprintf(fid, 'Px_DistRotCentre2PistonFixture_OA = %f\n', Hydr.AO);
fprintf(fid, 'Px_ZeroPosPitchAngle              = %f\n', Hydr.Pdz);
fprintf(fid, 'Px_PitchGeometryCrankRadius       = %f\n', Hydr.R);
fprintf(fid, 'Px_PitchGeometryCylY              = %f\n', Hydr.Ya);
fprintf(fid, 'Px_PitchGeometryCylX              = %f\n', Hydr.Xa);
fprintf(fid, 'Px_PitchGeometryMinCyl            = %f\n', Hydr.k);
fprintf(fid, 'Px_PitchGeometryAngleOffset       = %f\n', Hydr.Pdz);
fprintf(fid, 'Px_PitchGeometryOffsetMod         = %f\n', 0);
fprintf(fid, 'Px_PitchGeometryA0                = %f\n', 0);
fprintf(fid, 'Px_PitchGeometryA1                = %f\n', 0);
fprintf(fid, 'Px_PitchGeometryA2                = %f\n', 0);
fprintf(fid, 'Px_PitchGeometryA3                = %f\n', 0);
fprintf(fid, 'Px_PitchGeometryA4                = %f\n', 0);

fprintf(fid, '\n------=========  Safety Pitch Hydraulics =========------\n\n');
fprintf(fid, 'Px_SafetyPitchHydraulics_AccVolume                        = %f\n', Hydr.effectiveVolAcc*1e3);
fprintf(fid, 'Px_SafetyPitchHydraulics_DistRotCentre2PistonFixture_OA   = %f\n', Hydr.AO);
fprintf(fid, 'Px_SafetyPitchHydraulics_MinPistonPos                     = %f\n', Hydr.k);
fprintf(fid, 'Px_SafetyPitchHydraulics_Orifice1_Diameter                = %f\n', Hydr.Orifice1_Diameter);
fprintf(fid, 'Px_SafetyPitchHydraulics_Orifice2_Diameter                = %f\n', Hydr.Orifice2_Diameter);
fprintf(fid, 'Px_SafetyPitchHydraulics_PistonDiameter                   = %f\n', Hydr.d_piston);
fprintf(fid, 'Px_SafetyPitchHydraulics_PitchMovementRadius              = %f\n', Hydr.R);
fprintf(fid, 'Px_SafetyPitchHydraulics_PitchSpeedHigh                   = %f\n', Hydr.PitchSpeedHigh);
fprintf(fid, 'Px_SafetyPitchHydraulics_PitchSpeedLow                    = %f\n', Hydr.PitchSpeedLow);
fprintf(fid, 'Px_SafetyPitchHydraulics_PrechargePressure                = %f\n', Hydr.preChargePressureAcc*1e-5);
fprintf(fid, 'Px_SafetyPitchHydraulics_ZeroPosAlfaAngle                 = %f\n', Hydr.alpha_min);
fprintf(fid, 'Px_SafetyPitchHydraulics_ZeroPosPitchAngle                = %f\n', Hydr.Pdz);

fprintf(fid, '\n------=========  Safety Pitch Hydraulics Patronus =========------\n\n');
fprintf(fid, 'Px_SafetyPitchHydraulics_AccVolume                        = %f\n', Hydr.effectiveVolAcc*1e3);
fprintf(fid, 'Px_SafetyPitchHydraulics_DistRotCentre2PistonFixture_OA   = %f\n', Hydr.AO);
fprintf(fid, 'Px_SafetyPitchHydraulics_EMFPressure                      = %f\n', 240);
fprintf(fid, 'Px_SafetyPitchHydraulics_FastValveDelayOff                = %f %s\n', 0.05,';%Note tuning parameter');
fprintf(fid, 'Px_SafetyPitchHydraulics_FastValveDelayOn                 = %f %s\n', 0.08,';%Note tuning parameter');
fprintf(fid, 'Px_SafetyPitchHydraulics_MinPistonPos                     = %f\n', Hydr.k);
fprintf(fid, 'Px_SafetyPitchHydraulics_Orifice1_Diameter                = %f\n', Hydr.Orifice1_Diameter);
fprintf(fid, 'Px_SafetyPitchHydraulics_Orifice2_Diameter                = %f\n', Hydr.Orifice2_Diameter);
fprintf(fid, 'Px_SafetyPitchHydraulics_PilotValveDelay                  = %f %s\n', 0.11,';%Note tuning parameter');
fprintf(fid, 'Px_SafetyPitchHydraulics_PistonDiameter                   = %f\n', Hydr.d_piston);
fprintf(fid, 'Px_SafetyPitchHydraulics_PitchMovementRadius              = %f\n', Hydr.R);
fprintf(fid, 'Px_SafetyPitchHydraulics_PitchSpeedGainFactor             = %f %s\n', 1,';%Note tuning parameter');
fprintf(fid, 'Px_SafetyPitchHydraulics_PitchSpeedOrificeGainFactor      = %f %s\n', 1,';%Note tuning parameter');
fprintf(fid, 'Px_SafetyPitchHydraulics_PitchSpeedLow                    = %f\n', Hydr.PitchSpeedLow);
fprintf(fid, 'Px_SafetyPitchHydraulics_PrechargePressure                = %f\n', Hydr.preChargePressureAcc*1e-5);
fprintf(fid, 'Px_SafetyPitchHydraulics_RodDiameter                      = %f\n', Hydr.d_rod);
fprintf(fid, 'Px_SafetyPitchHydraulics_ZeroPosAlfaAngle                 = %f\n', Hydr.alpha_min);
fprintf(fid, 'Px_SafetyPitchHydraulics_ZeroPosPitchAngle                = %f\n', Hydr.Pdz);
fprintf(fid, 'Px_SafetyPitchHydraulics_nreg                             = %f\n', 0.5);

% VTS inputs
fprintf(fid, '\n------========= VTS parameters =========------\n\n');
fprintf(fid, 'a0                = %d\n', Hydr.pcell(5));
fprintf(fid, 'a1                = %d\n', Hydr.pcell(4));
fprintf(fid, 'a2                = %d\n', Hydr.pcell(3));
fprintf(fid, 'a3                = %d\n', Hydr.pcell(2));
fprintf(fid, 'a4                = %d\n', Hydr.pcell(1));

fprintf(fid, 'Xmin1             = %d\n', 0);
fprintf(fid, 'Xmin2             = %d\n', 0);
fprintf(fid, 'Xmin3             = %d\n', 0);
fprintf(fid, 'Xmax1             = %d\n', Hydr.x_stroke*1e3);
fprintf(fid, 'Xmax2             = %d\n', Hydr.x_stroke*1e3);
fprintf(fid, 'Xmax3             = %d\n', Hydr.x_stroke*1e3);

fprintf(fid, 'PiMin1            = %d\n', rad2deg(Hydr.Pdz));
fprintf(fid, 'PiMin2            = %d\n', rad2deg(Hydr.Pdz));
fprintf(fid, 'PiMin3            = %d\n', rad2deg(Hydr.Pdz));
fprintf(fid, 'PiMax1            = %d\n', Hydr.PiMax);
fprintf(fid, 'PiMax2            = %d\n', Hydr.PiMax);
fprintf(fid, 'PiMax3            = %d\n', Hydr.PiMax);

% _PL inputs
fprintf(fid, '\n------========= _PL file =========------\n\n');
fprintf(fid, '\nPIT:\n');
fprintf(fid, '1 \n');
fprintf(fid, '%.02f R Radius of crank [mm] \n', Hydr.R*1e3);
fprintf(fid, '%.02f pitch cylinger angle position at 0 degr. pitch [degr.] \n', Hydr.alpha0_vts*180/pi);
fprintf(fid, '%.02f A Distance of cylinder bracket in x direction [mm] \n', Hydr.Xa*1e3);
fprintf(fid, '%.02f L Distance of cylinder bracket in y direction [mm] \n', Hydr.Ya*1e3);
fclose(fid);
%winopen([outputfolder '\pitch_translate_' Hydr.name '_' regexprep(char(date),{'-'},{''}) '.txt'])

%% Plots?
if plotfig
    theta_fit_deg = Hydr.pcell(5) + x*Hydr.pcell(4)+x.^2*Hydr.pcell(3)+x.^3*Hydr.pcell(2)+x.^4*Hydr.pcell(1);
    hold on; grid on;
    plot(theta_fit_deg,x)
    plot(rad2deg(theta),x)
    xlabel 'Angle [deg]'; ylabel 'Cylinder stroke [m]';
    legend('analytical','fit')
end
end
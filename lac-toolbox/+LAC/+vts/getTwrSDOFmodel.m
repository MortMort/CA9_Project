function [ twr ] = getTwrSDOFmodel(masfile, gravityCorrection, visualize)
%GETTWRSDOFMODEL - Builds a SDOF model for the tower first oscillation mode
% Includes the effects of gravity to the stiffness
% M*X'' + K*X' + C*X = Ft + M*g*l*sin(theta)
% ~ Approximated for small angles to:
% M*Y'' + K*Y' + C*Y = Ft + M*g*Y/l
% where,
% Y'': acceleration
% Y' : speed
% Y  : displacement
% M  : Mass
% K  : Stiffness
% C  : Damping coefficient
% g  : 9.81 m/s^2
% l  : Tower height
% Ft : Thrust force
% 
% Syntax:  [ twr ] = getTwrSDOFmodel(masfile, gravityCorrection, visualize)
%
% Inputs:
%    masfile            - Path to VTS master file
%    gravityCorrection  - Boolean, default true. Enables stiffness
%    correction due to gravity
%    visualize          - Boolean, visualization of bode plot of SDOF model
%
% Outputs:
%    twr      - structure containing all the information for the tower
%    twr.SDOF - continous time single degree of freedom model of the tower
%    twr.info - information on how to re-run this script
%    twr.properties - tower properties used to derive the SDOF model
%
% Example: 
%    masfile = 'h:\FEATURE\HighTowers\NewCtr\002\Mk3A_V126_3.45MW_113.3_hh137\006\01_000\Loads\INPUTS\IEC3A_3450kW_137HH_igear113.mas';
%    twr     = Tower.getTwrSDOFmodel(masfile, true, true);
%
% Other m-files required: none
% Subfunctions: none
% MAT-files required: none
%
% See also: 

% Author: FACAP, Fabio Caponetti
% June 2016; Last revision: 06-June-2016

if nargin<3
    visualize = false;
end

if nargin<2 || isempty(gravityCorrection)
    % Selects if to apply the gravity effects to the stiffness matrix
    gravityCorrection   = true;
end

%% TOWER PROPERTIES

% Converts master file into structure
mas         = LAC.vts.convert(masfile);

% Calculations
% Tower height (including foundation)
towerHeight     = max(mas.twr.ElHeight);
hubHeight       = mas.turb.HubHeight;
eModule         = mas.twr.Emodule;
logDecDamp      = mas.twr.LogDL1;

% ElDiameter(i) = (ElDiameter(i)+ElDiameter(i+1))/2;
% ElRadius(i)   = ElDiameter(i)/2; 
rThickenss     = mas.twr.ElThickness;
rA             = mas.twr.ElDiameter;
rB             = rA-2*rThickenss;

%rA          = (mas.twr.ElDiameter(1:end-1)+mas.twr.ElDiameter(2:end))/2/2; % Average outer diameter between two sections; divided by 2 to get radius. 
%rB          = rA - (mas.twr.ElThickness(1:end-1)+mas.twr.ElThickness(2:end))/2; % Average thickness between two sections. inner radius. 
% Area moment of inertia on tower sections, 
% see http://www.engineeringtoolbox.com/area-moment-inertia-d_1328.html
I           = pi/64 * (mean(rA)^4-mean(rB)^4); % Tower is approximated to cylinder with even radius

% Nacelle, blade and hub mass
massNac     = mas.nac.NacelleMass; 
massBld     = sum(diff(mas.bld.Radius).*mas.bld.m(2:end)); % need to integrate to get blade mass (i.e. only in out-file)
massHub     = mas.rot.HubMass;
% Mass, towerTopMass = 3*blades + hub + nacelle
massTwrTop  = 3*massBld + massHub + massNac;

%% Tower SDOF model, models the tower as a weightless cylinder

% Spring coefficient, stiffness
ky = 3*eModule*I/towerHeight^3;

% Damper coefficient, see: https://en.wikipedia.org/wiki/Damping_ratio
cy = 2*logDecDamp*sqrt(ky*massTwrTop);

% Gravity correction to the stiffness coefficient
if gravityCorrection
    % Stiffness correction for gravity i.e. gravity pulling tower
    % Model: 
    % y : displacement, yAngle : displacement angle
    % stfGCorr = g*sin(yAngle) ~ g*yAngle ~ g*y/towerHeight
    stfGCorr     = 9.81/towerHeight;
    % Critical buckling load (fixed-free), F = pi^2*I/(K*L)^2
    % F = maximum or critical force (vertical load on column),
    % E = modulus of elasticity,
    % I = area moment of inertia of the cross section of the rod
    % L = unsupported length of column,
    % K = column effective length factor, whose value depends on the conditions of end support of the column, as follows.
    %      For both ends pinned (hinged, free to rotate), K = 1.0.
    %      For both ends fixed, K = 0.50.
    %      For one end fixed and the other end pinned, K ~ 0.699.
    %      For one end fixed and the other end free to move laterally, K = 2.0.
    %      KL is the effective length of the column
    % See: https://en.wikipedia.org/wiki/Buckling
    criticalLoad = pi^2*eModule*I/(2*towerHeight)^2;
    verticalLoad = massTwrTop*9.81;
    % Correction coefficient for the frequency, see DMS.0048-4131
    frqGcorr     = sqrt(1-verticalLoad/criticalLoad);
else
    % Stiffness correction for gravity
    stfGCorr    = 0; 
    % Frequency correction for gravity
    frqGcorr    = 1;
end

% Calculates the tower natural frequency (the two formulations below are
% equivalent)
% twrNatFrq    = sqrt(ky/massTwrTop)/(2*pi)*frqGcorr
twrNatFrqGravityCorrected  = sqrt(ky/massTwrTop - stfGCorr)/(2*pi);
% Calculates the non-gravity corrected frequency (just for reference)
twrNatFrq                  = sqrt(ky/massTwrTop)/(2*pi);

%% State space model

% State matrix
A = [  0    1 
     -ky/massTwrTop+stfGCorr -cy/massTwrTop
     ];
% Input-to-state matrix
B = [ 0 
     1/massTwrTop ];
% State-to-output matrix
C = [ 1 0
      0 1];
% Input-to-output matrix
D = [ 0 
      0 ];
% Tower fore-aft SDOF model
twrTf = ss(A, B, C, D); 
% Model description
twrTf.InputName  = 'Force';
twrTf.OutputName = {'MeasPosition'; 'MeasSpeed'};
twrTf.StateName  = {'Position'; 'Speed'};
[~, masFileName] = fileparts(masfile);
twrTf.Name       = masFileName;

if strcmpi(version('-release'), '2015a')
    twrTf.InputUnit  = 'N';
    twrTf.OutputUnit = {'m'; 'm/s'};
    twrTf.StateUnit  = {'m'; 'm/s'};
end



%% Output

% Script information
twr.info.dateGenerated      = datestr(now);
twr.info.masFile            = masfile;
twr.info.gravityCorrection  = mat2str(boolean(gravityCorrection));

% Extracted tower properties
twr.properties.hubHeight            = hubHeight;
twr.properties.towerHeight          = towerHeight;
twr.properties.eModule              = eModule;
twr.properties.logDecDamp           = logDecDamp;
twr.properties.massTwrTop           = massTwrTop;
twr.properties.massBlade            = massBld;
twr.properties.massHub              = massHub;
twr.properties.massNacelle          = massNac;
twr.properties.avgOuterRadius       = mean(rA);
twr.properties.avgInnerRadius       = mean(rB);
twr.properties.areaMomentOfInertia  = I;
twr.properties.stiffness            = ky;
twr.properties.dampingCoeff         = cy;
twr.properties.twrNatFrqGravityCorrected            = twrNatFrqGravityCorrected;
twr.properties.twrNatFrq            = twrNatFrq;
twr.properties.criticalBucklingLoad = criticalLoad;
twr.properties.frqCorrectionFactor  = frqGcorr;

% Single degree of freedom transfer function
twr.SDOF = twrTf;

%% Bode plot visualization

if visualize
    bodePlotOpts = bodeoptions;
    bodePlotOpts.PhaseWrapping  = 'on';
    bodePlotOpts.Grid           = 'on';
    bodePlotOpts.FreqUnits      = 'Hz'; 
    bodeplot(twr.SDOF, bodePlotOpts);
end
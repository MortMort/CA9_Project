clc; clear variables; close all

% addpath(genpath('w:\SOURCE\MatlabToolbox\LACtoolbox\master\'));
addpath('h:\ENVENTUS\Mk1a\Variants\F3\Investigations\141_Turner_Gear_SBI\01_GC\');
% setup

p = inputParser;

paramName1 = 'filepath_load_paths';
paramName2 = 'output_folder';
paramName3 = 'mymbr_limit';
paramName4 = 'SmomBLD';
paramName5 = 'GravityCorrection';

Val1 = 'h:\ENVENTUS\Mk1a\Variants\F3\Investigations\141_Turner_Gear_SBI\01_GC\PathList_F3_80p.txt';
% Val1 = 'h:\ENVENTUS\Mk1a\Variants\F3\Investigations\141_Turner_Gear_SBI\01_GC\PathList_F3_98p.txt';
Val2 = 'h:\ENVENTUS\Mk1a\Variants\F3\Investigations\141_Turner_Gear_SBI\01_GC\TurnerGear_GC\Results\';
Val3 = 11681.89; % Reference
Val4 = 5.803E+05; % BLD's Smom in kg.m (as in VTS *.out file)
Val5 = 1.16; % Gravity Correction (Look in [EXT/Abs/] PLF values for Mr sensors)

addOptional(p,paramName1,Val1);
addOptional(p,paramName2,Val2);
addOptional(p,paramName3,Val3);
addOptional(p,paramName4,Val4);
addOptional(p,paramName5,Val5);

parse(p,paramName1,Val1);
parse(p,paramName2,Val2);
parse(p,paramName3,Val3);
parse(p,paramName4,Val4);
parse(p,paramName5,Val5);

LAC.scripts.TurnerGearLoads.TurnerGearGC(p.Results);

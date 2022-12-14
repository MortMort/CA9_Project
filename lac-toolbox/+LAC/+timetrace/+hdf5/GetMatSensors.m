function [SensorSym, SensorDesc, AddOut] = GetMatSensors(file, geninfo, usersettings)
% Read sensors from *.mat file (SensorDesc and SensorSym varibles)
% Internal VDAT function
%
% JEB, December 23, 2003

AddOut = [];

load(file)

% No check is made regarding the existense of SensorSym and SensorDesc in the *.mat file.
% This was made in prior call to 'readmat.m'

%  Check for exisitence of duplicate sensors added by LAVKR/PBC
SensorSymCell=cellstr(SensorSym);
SensorSymCell=UniqueSensorSymbols(SensorSymCell,usersettings.AutoRenameDuplSens);
SensorSymModified=char(SensorSymCell);
SensorSym=SensorSymModified;






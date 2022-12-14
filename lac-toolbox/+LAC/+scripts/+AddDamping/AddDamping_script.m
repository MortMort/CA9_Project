%% Caller for the Wrapper: Detects EVs, Adds edgewise blade damping and resubmits LCs.
% Wrapper: Detects EVs, Adds edgewise blade damping and resubmits LCs.
%
% LAC WIKI: Detect & Dampen Edgewise Vibrations In Idling, Maintenance Load Cases
% http://wiki.tsw.vestas.net/pages/viewpage.action?pageId=175997177

clc; clear all; close all

SimFolders = {
    'W:\USER\PECJA\Stability\LC_damping\Test'
    'W:\USER\PECJA\Stability\LC_damping\Test_SubSet'
    };

% Multiple inputs can be given inclduing sensor selection, DLC selection ect.
% Plese write "help LAC.scripts.AddDamping.damping_wrapper" in the command 
% line to read more. 
LAC.scripts.AddDamping.damping_wrapper(SimFolders,'margin',2.0,'forceread',true)
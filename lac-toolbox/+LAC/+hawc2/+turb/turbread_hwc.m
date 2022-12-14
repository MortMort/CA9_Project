function [turb] = turbread_hwc(fn, Vnav, Ti, NST, NAT, N2T)
%TURBREAD_HWC
%
% Read HAWC2 turbulence box in flex int format. 
% 
% The box dimensions are supplied as user input since the HAWC2 
% turbulence data does not contain any header information.
%
% JOSOW 2021
%
% fn = filename
% Vnav = average velocity
% Ti = turbulence intensity
% NST = Number of horizontal (crosswind) stations
% NAT = Number of vertical stations
% N2T = Number of time-wise (downwind) stations
    % Check size
    fdata = dir(char(fn));
    if(fdata.bytes ~= NST*NAT*N2T*4)
        error('[ERROR] turbread_hwc: Supplied box dimensions inconsistent with file size');
    end
    
    % Read turbulence data
    fid = fopen(fn,'r');
    turb = fread(fid, 'single');
    turb = reshape(turb, [NST, NAT, N2T]);
    turb = permute(turb, [3,2,1]);
    turb = flip(flip(turb, 2), 3);
    turb = turb*Vnav*Ti;
end
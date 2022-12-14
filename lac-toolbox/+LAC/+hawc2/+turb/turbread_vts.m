function [turb] = turbread_vts(fn, Vnav, Ti)
%TURBREAD_VTS
%
% Read a turbulence box in flex int format.
%
% Based on MISVE example.
%
% JOSOW 2021
%
% Usage: 
% fn = filename
% Vnav = average velocity
% Ti = turbulence intensity

    fid = fopen(fn,'r');
    fread(fid,50,'int8');
    turb.NST=fread(fid,1,'int16'); % Horizontal
    turb.NAT=fread(fid,1,'int16'); % Vertical
    turb.NVT=fread(fid,1,'int16');
    turb.N2T=fread(fid,1,'int16');
    Ifak=fread(fid,1,'uint16');
    turb.horizontalStations = fread(fid,turb.NST/2,'single');%horizontal
    turb.verticalStations = fread(fid,turb.NAT/2,'single');%vertical
    turb.SA=fread(fid,4,'single');
    turb.dt = turb.SA(1);  % Timestep downwind
    turb.Vmean = turb.SA(2); % Mean wind speed
    turb.stationSpacing = turb.SA(3); % Station spacing in rotor plane
    turb.lengthScale = turb.SA(4); % Length scale

    % Create empty 
    turb.dat=zeros(turb.N2T,turb.NST,turb.NAT);
    
    % Derive multiplication factor for integer data
    Tfak=Vnav*Ti/Ifak;
    
    % Read integer data and apply factor
    d = Tfak * fread(fid, turb.NVT*turb.NST*(turb.N2T+1), 'int16');  

    % Permute into format nX * nY * nZ
    turb.dat = permute(reshape(d,turb.NST,turb.NAT,(turb.N2T+1)),[3,2,1]);

    fclose(fid);
end
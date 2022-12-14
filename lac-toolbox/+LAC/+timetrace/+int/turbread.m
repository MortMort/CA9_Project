function [turb] = turbread(fn, Vnav, Ti)
%SYNTAX:
% [turb] = turbread(fn, Vnav, Ti)
%
%INPUT:
% fn = filename
% Vnav = wind speed at hub height [m/s]
% Ti = turbulence intensity
%
%OUTPUT:
% turb = structure with output data
% turb.NST = grid points in 1st direction
% turb.NAT = grid points in 2nd direction
% turb.N2T = number of time step
% turb.RST = radii station ( NOTE not sorted according to turb.dat)
% turb.dat = down wind turbulence field.
%
%

% [turb] = turbread(fn, Vnav, Ti);
%example: downwind = turbread('W:\wind\100_600.Mann\10012bu.int',12,0.155)+12;
%12 m/s, 15.5% turbulence.
%
%
%Version history:
%00: new script by unknown Author (script provided by LT)
%01: added to toolbox by SORSO

fid = fopen(fn,'r');
fread(fid,50,'int8');
turb.NST=fread(fid,1,'int16'); % Number of radial (vertical for square turb files) stations
turb.NAT=fread(fid,1,'int16'); % Number of tangential (horizontal for square turb files) stations
turb.NVT=fread(fid,1,'int16'); % Total number of time series (NST*NAT for square, NST*NAT+1 for cylindrical turb files)
turb.N2T=fread(fid,1,'int16'); % Number of "slices"
Ifak=fread(fid,1,'int16');
turb.RST=fread(fid,turb.NST,'single');
turb.SA=fread(fid,4,'single');
%turb.SA(1) = dtt, time step size
%turb.SA(2) = UT, mean wind speed
%turb.SA(3) = dL3, grid spacing (or 0 for cylindrical files)
%turb.SA(4) = L1, length scale
turb.dat=zeros(turb.N2T,turb.NAT,turb.NST);
Tfak=Vnav*Ti/Ifak;
d=fread(fid,turb.NVT*turb.N2T,'int16');
fclose(fid);
m=0;
for k=1:turb.N2T %time
    m=m-turb.NST*turb.NAT+turb.NVT; %Optionally add 1 to skip the center values for cylindrical turb files
    for i=1:turb.NAT %horizontal, right to left (azimuthal for cylindrical turb files)
        for j=1:turb.NST %vertical, top to bottom (radial for cylindrical turb files)
            m=m+1;
            turb.dat(k,i,j)=Tfak*d(m);
        end
    end
    
end
if turb.NVT == (turb.NAT*turb.NST+1),
    turb.center=Tfak*d(1:turb.NVT:end);
end


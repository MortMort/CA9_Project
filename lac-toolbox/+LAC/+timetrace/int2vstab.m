function int2vstab(filename,t1,t2,dt,outfile)
% Writes input file for Vstab based on .int file. Parameters are vhub,
% pitch angle and rotor speed.
%
% Inputs
% filename: name of int-file
% t1:       start time for parameter extraction
% t2:       end time for parameter extraction
% dt:       time step for parameter extraction
% outfile:  name of output file for vstab
%
% syntax: int2vstab(filename,t1,t2,dt,outfile)

folder=fileparts(filename);
C=sensreadTL(fullfile(folder,'sensor'));
i_pi = sensNoTL(C,'Pi2');
i_omega = sensNoTL(C,'Omega');
i_Vhub = sensNoTL(C,'Vhub');

[t,dat]=intreadTL(filename);

t_vstab=t1:dt:t2;
i_vstab=round(1/(t(2)-t(1))*t_vstab);

pi=dat(i_vstab,i_pi);
omega=dat(i_vstab,i_omega);
Vhub=dat(i_vstab,i_Vhub);

vstabData=[Vhub pi pi pi zeros(length(t_vstab),1) zeros(length(t_vstab),1) omega];

fid=fopen(outfile,'w');
fprintf(fid,'%6.2f %6.2f %6.2f %6.2f %6.2f %6.2f %6.2f\n',vstabData');
fclose(fid);
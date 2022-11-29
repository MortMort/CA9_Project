function OutInfo=readout(OutFile)
%Extracts turbine data from an outfile

%JADGR, Mar 2012

RTGEO=-9;
BMDIST=-9;
HUBSHFT=-9;
fid = fopen(OutFile);
j=0;
while ~feof(fid)
    tline=fgetl(fid);
    j=j+1; 
    
    %Rotor and tower geometry
    if length(tline)>23 && strcmp(tline(1:24),'Rotor and tower geometry')
        RTGEO=j;
    end
    if (RTGEO==j-4)
        regex='.*D.*?=(.*?)m';
        [~,~,~,~,C,~,~]=regexp(tline,regex);
        dia=str2double(C{1}{1});
        OutInfo.rot.diameter=dia;
    end
    
    %Hub and main shaft
    if length(tline)>21 && strcmp(tline(1:22),'Data for hub and shaft')
        HUBSHFT=j;
    end
    if (HUBSHFT==j-5)
        regex='.*JYhub.*?=(.*?)kgm2';
        [~,~,~,~,C,~,~]=regexp(tline,regex);
        Imom=str2double(C{1}{1});
        OutInfo.hub.inertiaY=Imom;
    end
    
    %Blade mass distribution
    if length(tline)>31 && strcmp(tline(1:32),'Data for blade mass distribution')
        BMDIST=j;
    end
    if (BMDIST==j-4)
        regex='.*Imom.*?=(.*?)kgm2';
        [~,~,~,~,C,~,~]=regexp(tline,regex);
        Imom=str2double(C{1}{1});
        OutInfo.blade.inertia=Imom;
    end
    
    
end
fclose(fid);


function MasInfo =readmas(MasFile,V03)
% Reads Master files from VTS

% Original version by?
% JADGR, 24. Apr 2012 - Added reading of effecincy tables, generator
%                       information, converter information and pitch table. 

if nargin < 2
    V03=false;
end
%% Finding info in masterfile, depending on V03 switch
MasInfo=findinfo(MasFile,V03);

function MasInfo=findinfo(MasFile,V03)
startrpm=-9;
gear=-9;
twrname=-9;
NoHeader =0;
EEff=-9;
MEff=-9;
ALoss=-9;
CNV=-9;
PIT=-9;
GEN=-9;
fid = fopen(MasFile);
j=0;
while ~feof(fid)
    tline=fgetl(fid);
    j=j+1; 
    if V03
        if length(tline)>3 && strcmpi(tline(1:4),'GEN:')
            startrpm=j;
        end
        if startrpm==j-3
            genline=tline;
            B=seperate(tline);
            MasInfo.NomRPM=str2num(B{2});
        end
    end
    %  error('Cannot find ProdCtrl_params.csv file')
    
    %Generator parameters
    if length(tline)>3 && strcmpi(tline(1:4),'GEN:')
        GEN=j;
    end
    if GEN==j-1
        C=sscanf(tline,'%f');
        MasInfo.gen.poles=C(1);
        MasInfo.gen.freq=C(2);
        MasInfo.gen.constLoss=C(3);
    end
    
    %Electrical effeciency table
    if length(tline)>6 && strcmpi(tline(1:7),'G1 Elec')
        EEff=j;
    end
    switch(j-EEff)
        case 1
            C=sscanf(tline,'%d%d');
%           MasInfo.gen.ElecEff.power=dlmread(MasFile,'',[j 0 j C(2)-1]);
            MasInfo.gen.ElecEff.rpm=dlmread(MasFile,'',[j+1 0 j+C(1) 0]);
            MasInfo.gen.ElecEff.data=dlmread(MasFile,'',[j+1 1 j+C(1) C(2)]);
        case 2
            MasInfo.gen.ElecEff.power=sscanf(tline,'%f');
    end
    
    %Mechanical effeciency table
    if length(tline)>6 && strcmpi(tline(1:7),'G1 Mech')
        MEff=j;
    end
    switch(j-MEff)
        case 1
            C=sscanf(tline,'%d%d');
%           MasInfo.gen.MechEff.power=dlmread(MasFile,'',[j 0 j C(2)-1]);
            MasInfo.gen.MechEff.rpm=dlmread(MasFile,'',[j+1 0 j+C(1) 0]);
            MasInfo.gen.MechEff.data=dlmread(MasFile,'',[j+1 1 j+C(1) C(2)]);
        case 2
            MasInfo.gen.MechEff.power=sscanf(tline,'%f');
    end
    
    %Aux loss tables
    if length(tline)>11 && strcmpi(tline(1:12),'AuxLossTable')
        ALoss=j;
    end
    switch(j-ALoss)
        case 1
            C=sscanf(tline,'%d%d');
            MasInfo.gen.AuxLoss.data=dlmread(MasFile,'',[j+1 1 j+C(1) C(2)]);
            MasInfo.gen.AuxLoss.rpm=dlmread(MasFile,'',[j+1 0 j+C(1) 0]);
            %Changed to increase robustness to comments
            %MasInfo.gen.AuxLoss.power=dlmread(MasFile,'',[j 0 j+C(2)-1]);
        case 2
            MasInfo.gen.AuxLoss.power=sscanf(tline,'%f');
    end 
           
    %Converter parameters
    if length(tline)>3 && strcmpi(tline(1:4),'CNV:')
        CNV=j;
    end
    if CNV==j-1
        C=sscanf(tline,'%f');
        MasInfo.cnv.TauP=C(1);
        MasInfo.cnv.TauI=C(2);
        MasInfo.cnv.Kp=C(3);
    end
    
    %Pitch parameters
    if length(tline)>3 && strcmpi(tline(1:4),'PIT:')
        PIT=j;
    end
    if PIT==j-1
        C=sscanf(tline,'%f');
        MasInfo.pit.TauP=C(2);
        MasInfo.pit.delay=C(4);
    end
    if (PIT==j-6)
        C=sscanf(tline,'%d%d');
        MasInfo.pit.table.pitchMoment=dlmread(MasFile,'',[j 0 j C(2)-1]);
        MasInfo.pit.table.voltage=dlmread(MasFile,'',[j+1 0 j+C(1) 0]);
        MasInfo.pit.table.data=dlmread(MasFile,'',[j+1 1 j+C(1) C(2)]);
    end
    
    %% find drivetrain in masfile
    if length(tline)>3 && strcmpi(tline(1:4),'DRT:')
        gear=j;
    end
    if gear==j-1
        C=sscanf(tline,'%f');
        MasInfo.drt.tors=C(4);        
    end
    if gear==j-3
        genline=tline;
        C=sscanf(tline,'%f');
        MasInfo.drt.Jgen=C(1);
        MasInfo.drt.Ngear=C(2);
    end
    %% find tower in masfile
    if length(tline)>3 && strcmpi(tline(1:4),'TWR:')
        twrname=j;
        D=sscanf(tline,'TWR: %s');
        MasInfo.twr.name=D;
    end
    if twrname==j-8+2*V03 % (position of tower top, depending on V03 setup or not.
        E=sscanf(tline,'%f');
        Topthickness=E(3);
        % towers should have 20mm top section as standard
        if Topthickness < 0.020
            % listing tower exceptions
            if length(MasInfo.twr.name)>8 && strcmp(MasInfo.twr.name(1:9),'0015-9348')
                msgbox('Tower is not V112 or Mk2 prog. tower, frq. could be too high compared to a new tower.','Tower structure','warn')
            end
        end
    end    
end
if isfield(MasInfo,'NomRPM') && isfield(MasInfo,'Ngear')
    MasInfo.Nom1P=(MasInfo.NomRPM/MasInfo.Ngear)/60;
end
fclose(fid);


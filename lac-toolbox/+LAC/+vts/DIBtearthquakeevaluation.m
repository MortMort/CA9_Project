function DIBtearthquakeevaluation(masfile)   
%   Creating a seperate postload folder for the seismic evaluation. 
%   Run both the aerodynamic load evaluation with IntPostD and the seismic load calculation using SeismicLoads
%   The earthquake evaluation is required for DIBt tower design
%   Syntax:
%       LAC.vts.earthquakecalculation(masfile)
%
%   Input:  
%   masfile = Full path to master file.
%
%   Output: 
%   A .txt file in a \EQKPostloads\ folder containing loads contribution from
%   aerodynamic and seismic loads.
%
%   Example:
%   EqkPost('C:\VTSSimulation\Loads\Inputs\myfile.mas')
%
%	Version History:
%   00:     new script    

    loadcases={'11','51'}; %include following load cases for the aerodynamic evaluation
    projname='EQK_calc';
    
    % find input for IntPostD call
    frqfile_ext='.frq';
    txtfile_ext='.txt';
    masfile_ext='.mas';
    [pathstr,name,ext] = fileparts(masfile);
    masfile=fullfile(pathstr,sprintf('%s%s',name,masfile_ext));
    txtfile=fullfile(pathstr,sprintf('%s%s',name,txtfile_ext));
    frqfile=fullfile(pathstr,sprintf('%s%s',name,frqfile_ext));
    intdir=strrep(pathstr,'INPUTS','INT');
    sensorfile=fullfile(intdir,'sensor');
    
    % create output directory
    outputdir=strrep(pathstr,'INPUTS','Postloads_EQK');
    cd(sprintf('%s\\..\\',pathstr));
    workdir=pwd;
    mkdir(outputdir);
  
    % create frq file for aerodynamic loads.
    aerofrqFile = fullfile(pathstr,sprintf('%s_EQK%s',name,frqfile_ext));
    createfrequencyfile(frqfile,aerofrqFile,loadcases);
    
    %run IPD to get aerodynamic twr loads
    cmdcall=sprintf('IntPostD -outputdir %s -masfile %s -sensorfile %s -txtfile %s  %s',outputdir,masfile,sensorfile,txtfile,aerofrqFile);
    status = dos(cmdcall)
    
    %Run SeismicLoads noninteractive
    waitfor(SeismicLoads(outputdir,masfile,projname));
    
    %Combine results
    EqkCombine(outputdir,projname);
end

function createfrequencyfile(fileR,fileW,loadcases)
    FileIdR = fopen(fileR,'r'); %read from file
    FileIdW = fopen(fileW,'w'); %write to file
    
    %Reads header lines
    for i=1:9
       tline = fgetl(FileIdR);
       fprintf(FileIdW,'%s\r\n',tline);
    end
    
    %Writing only selected load cases
    while ~feof(FileIdR)
        tline = fgetl(FileIdR);
        for i=1:length(loadcases)
            if length(tline)>=length(loadcases{i})
                if strcmp(tline(1:length(loadcases{i})),loadcases{i})==1;         
                    fprintf(FileIdW,'%s\r\n',strrep(tline,' 1.35 ',' 1.00 '));
                end
            end
        end
    end
    
    fclose(FileIdR);
    fclose(FileIdW);    
end

function EqkCombine(EQKdir,Projname)    
%   Combine aerodynamic and seismic earthquake loads in a .txt file readu to copy/paste into the tower load document
%   Syntax:
%       EqkCombine(EQKdir,Projname)
%
%   Input:  
%   EQKdir = Path to the postload folder containing the aerodynamic and seismic load files.
%   Projname = name of the seismic load file
%
%   Output: 
%   a .txt file containing the aerodynamic, seismic and combined load
%   tables
%
%   Example:
%   EqkCombine('C:\VTSSimulation\Loads\EQKPostloads\','DIBT_seismicLoads'')
%
%	Version History:
%   00:     new script 

%Combine Aero and Seismic twr loads
    CombineLoadsFile=fullfile(EQKdir,'CombinedEqkLoads.txt');
    
    AeroTWRloadsFile=fullfile(EQKdir,'TWR','TWRload.txt');
    if ~exist(AeroTWRloadsFile, 'file')
        disp(sprintf('Input file not foun: %s',AeroTWRloadsFile));
    end
    
    SeismicTWRloadsFile=fullfile(EQKdir,sprintf('%s_worst.txt',Projname));
    if ~exist(SeismicTWRloadsFile, 'file')
        disp(sprintf('Input file not foun: %s',SeismicTWRloadsFile));
    end    
    
   
    %Read Aero Twrloads.txt
    FileIdAero = fopen(AeroTWRloadsFile,'r');
    %find '4.2 EXTREME LOADS'
    SearchStr='4.2 EXTREME LOADS';
    found=0;
    while ~found && ~feof(FileIdAero)
        tline = fgetl(FileIdAero);
        if length(tline)>=length(SearchStr)
            if strcmp(tline(1:length(SearchStr)),SearchStr)==1;         
                found=1;
            end
        end 
    end
    %skip blank lines
    tline = fgetl(FileIdAero);
    %read coloumnname
    tline = fgetl(FileIdAero);
    aerotabel.tablenames=strread(tline,'%s','delimiter',' ')';
    %read coloumnunit
    tline = fgetl(FileIdAero);
    aerotabel.tableunit=strread(tline,'%s','delimiter',' ')';                    
    %read values
    n=0;
    while ~isempty(strread(tline,'%s','delimiter',' '))
        if ~feof(FileIdAero)
            n=n+1;
            tline = fgetl(FileIdAero);
            if ~isempty(strread(tline,'%s','delimiter',' '))
                aerotabel.tablevalue(n,:)=strread(tline,'%s','delimiter',' ')';
            end
        else
            break
        end
    end
    fclose(FileIdAero);
    
    %Read Seismic *_worst.txt
    FileIdSeis = fopen(SeismicTWRloadsFile,'r');
    %find '#3 Resulting forces'
    SearchStr='#3 Resulting forces';
    found=0;
    while ~found && ~feof(FileIdSeis)
        tline = fgetl(FileIdSeis);
        if length(tline)>=length(SearchStr)
            if strcmp(tline(1:length(SearchStr)),SearchStr)==1;         
                found=1;
            end
        end 
    end
    %read coloumnname
    tline = fgetl(FileIdSeis);
    seismictabel.tablenames=strread(tline,'%s','delimiter',' ')';
       
    %read values 
    n=0;
    while ~isempty(strread(tline,'%s','delimiter',' '))
        if ~feof(FileIdSeis)
            n=n+1;
            tline = fgetl(FileIdSeis);
            if ~isempty(strread(tline,'%s','delimiter',' '))
                seismictabel.tablevalue(n,:)=strread(tline,'%s','delimiter',' ')';
            end
        else
            break
        end
    end
    fclose(FileIdSeis);
    
    %checks
    %same tower sections?
    
    %write eqk combined loads
    FileIdOutput = fopen(CombineLoadsFile,'w');
    PLF_Aero=1.10;
    PLF_Seis=1.0;
    
    fprintf(FileIdOutput,'File Generated by EqkCombine.m');
    fprintf(FileIdOutput,'\n');
    fprintf(FileIdOutput,'#1.1 Aerodynamic tower loads. All loads are characteristic loads i.e. no partialload factor is applied. Family method has been applied.');
    fprintf(FileIdOutput,'\n');
    fprintf(FileIdOutput,sprintf('%s%s%s\n',strpad(aerotabel.tablenames{1,1},6,' ','L'),strpad(aerotabel.tablenames{1,2},10,' ','L'),strpad('PLF',10,' ','L')));
    fprintf(FileIdOutput,sprintf('%s%s%s\n',strpad(aerotabel.tableunit{1,1},6,' ','L'),strpad(aerotabel.tableunit{1,2},10,' ','L'),strpad('[-]',10,' ','L')));
    for iSection=1:size(aerotabel.tablevalue,1)
        height=str2num(aerotabel.tablevalue{iSection,1});
        Mb=str2num(aerotabel.tablevalue{iSection,2});
        fprintf(FileIdOutput,sprintf('%6.1f%10.0f%10.2f\n',height,Mb,PLF_Aero));
    end
    fprintf(FileIdOutput,'\n\n');
    fprintf(FileIdOutput,'#1.2 Seismic tower loads. Resulting forces, highest loads of all ground conditions and all direction combinations.');
    fprintf(FileIdOutput,'\n');
    fprintf(FileIdOutput,sprintf('%s%s%s%s%s%s\n',strpad(seismictabel.tablenames{1,1},6,' ','L'),strpad(seismictabel.tablenames{1,4},10,' ','L'),strpad(seismictabel.tablenames{1,5},10,' ','L'),strpad(seismictabel.tablenames{1,6},10,' ','L'),strpad(seismictabel.tablenames{1,7},10,' ','L'),strpad('PLF',10,' ','L')));
    fprintf(FileIdOutput,sprintf('%s%s%s%s%s%s\n',strpad('[m]',6,' ','L'),strpad('[kN]',10,' ','L'),strpad('[kNm]',10,' ','L'),strpad('[kN]',10,' ','L'),strpad('[kNm]',10,' ','L'),strpad('[-]',10,' ','L')));
    for iSection=1:size(seismictabel.tablevalue,1)
        height=str2num(seismictabel.tablevalue{iSection,1});
        Fres=str2num(seismictabel.tablevalue{iSection,3});
        Mb=str2num(seismictabel.tablevalue{iSection,4});
        Fz=str2num(seismictabel.tablevalue{iSection,5});
        Mz=str2num(seismictabel.tablevalue{iSection,6});
        fprintf(FileIdOutput,sprintf('%6.1f%10.0f%10.0f%10.0f%10.0f%10.2f\n',height,Fres,Mb,Fz,Mz,PLF_Seis));
    end
    fprintf(FileIdOutput,'\n\n');
    
    fprintf(FileIdOutput,'#2.1 Combined aerodynamical and seismic tower loads.');
    fprintf(FileIdOutput,'\n');
    fprintf(FileIdOutput,sprintf('%s%s%s\n',strpad('Aerodynamic',25,' ','L'),strpad('Seismic',14,' ','L'),strpad('Combined',13,' ','L')));
    fprintf(FileIdOutput,sprintf('%s%s%s%s%s%s\n',strpad('Height [m]',10,' ','L'),strpad('Mb [kNm]',10,' ','L'),strpad('PLF',6,' ','L'),strpad('Mb [kNm]',10,' ','L'),strpad('PLF',6,' ','L'),strpad('Mb [kNm]',10,' ','L')));
    for iSection=1:size(aerotabel.tablevalue,1)
        height=str2num(aerotabel.tablevalue{iSection,1});
        Mb_aero=str2num(aerotabel.tablevalue{iSection,2});
        Mb_seis=str2num(seismictabel.tablevalue{iSection,4});
        Mb_Comb=Mb_aero*PLF_Aero+Mb_seis*PLF_Seis;
        fprintf(FileIdOutput,sprintf('%10.1f%10.0f%6.2f%10.0f%6.2f%10.0f\n',height,Mb_aero,PLF_Aero,Mb_seis,PLF_Seis,Mb_Comb));
    end
    fprintf(FileIdOutput,'\n');
    
    fclose(FileIdOutput);

    end
    
function [outstr]=strpad(instr,TotalLength,padchar,position)
    padsize=TotalLength-length(instr);
    padstr=instr;
    for i=1:(padsize)
        switch upper(position)
            case 'L'
                padstr=sprintf('%s%s',padchar,padstr);
            case 'R'
                padstr=sprintf('%s%s',padstr,padchar);
        end
    end
    outstr=padstr;
end
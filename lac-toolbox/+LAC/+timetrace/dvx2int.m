function [] = dvx2int(directory,prefix)
%DVX2INT -  Convert all dvx files in a folder to int-files.
%
%DVX-files in the specified folder are converted into int-files and written
%into a subfolder. A subset can be written by specifying a prefix to the
%files.
%
% Syntax:  [] = dvx2int(directory,preffix)
%
% Inputs:
%    directory  - Directory where dvx-files are located.
%    prefix     - Optional input, prefix for files to be processed.
%
% Outputs:
%    status     - Status on process.
%
% Example: 
%    [] = dvx2int(directory)
%    [] = dvx2int(directory,preffix)
%
% Other m-files required: LAC.timetrace.int.intwrite, vdat
% Subfunctions: none
% MAT-files required: none
%
% See also: LAC.timetrace.int.intwrite

% Author: MAARD, Martin Brødsgaard
% June 2015; Last revision: 10-June-2015

if nargin == 2
    filesearch = [prefix '*.dvx'];
else
    filesearch = '*.dvx';
end
LC = dir(fullfile(directory,filesearch));
mkdir(directory,'int\')
for j=1:length(LC)
    filename=fullfile(directory,LC(j).name);
    fprintf('Converting %i of %i: %s \n',j,length(LC),LC(j).name)
    try timetrace = vdat('convert',filename);        
        dvxinfo = timetrace.GenInfo;
        Xdata   =  timetrace.Xdata;
        Ydata   = timetrace.Ydata;
    catch
        warning('Could not read %s, file not converted.',filename)
        continue
    end
    converttointextention=strread(LC(j).name,'%s','delimiter','.');
    LAC.timetrace.int.intwrite(fullfile(directory,'int',[converttointextention{1} '.int']),Xdata(2)-Xdata(1),Ydata);
    clear Xdata Ydata
    
    if j==1
        fid = fopen(fullfile(directory,'int','sensor'),'w');
        fprintf(fid,'Sensor list: VTS002.V05.103 20130206100039841 \n');
        fprintf(fid,' No   forst  offset  korr. c  Volt    Unit   Navn    Beskrivelse--------------- \n');
        for i = 1:length(dvxinfo.SensorSym)
            fprintf(fid,'%3.0d    1.0    0.0    0.00      1.0    [-]    %s  %s \n',i,dvxinfo.SensorSym(i,:),dvxinfo.SensorDesc(i,:));
        end
        fclose(fid);
    end
end

function T = bladeTorsion(WSP,simdir,outPath)
%Function bladeTorsion(WSP,simdir,outpath)
% Script to extract the torsion of the blade and create .txt file with the
% results. Is based on the Power curve calculations at one wind speed.
%
% Input:
% 1: simdir  - directory of the folder containing the .sta, .int folders
% 2: WSP     - Mean wind speed for the turbine
% 3: outpath - Directory the .txt file is wanted, if empty current
%              directory is used.
%
% Output:
% 1: TorsionTable - .txt file with the radii and corresponding torsion
%                   along the blade
%
% Subfunctions: Needs 'w:\SOURCE\MatlabToolbox\LACtoolbox\develop\' - path
%               added
%
% Author: RUSJE, Rune Sønderby Jensen
% Oct 2017; Last revision: 20th-October-2017
%

% Directory to the DLC9.4 .sta files related to the wind speed
file=dir(fullfile(simdir,sprintf('STA\\94_Normal_Rho1.225_Vhfree_%0.1f*.sta',WSP)));
if(size(file,1)==0)
    file=dir(fullfile(simdir,sprintf('STA\\94_Normal_Rho1.225_Vhfree_%0.f*.sta',WSP)));
end
if (size(file,1)==0)
    file =dir(fullfile(simdir,sprintf('STA\\94*_%0.1f*.sta',WSP)));
end

SenObj = LAC.vts.convert(fullfile(simdir,'INT\sensor'),'SENSOR');

% Makes execution directory output path if none is specified.
if nargin <3
    outPath = pwd;
end

% Find all twist sensors for blade 2
n=1;
for j=1:length(SenObj.name)
    if (length(SenObj.name{j})>1)
        if (strcmp(SenObj.name{j}(1:2),'T2') && strcmp(SenObj.description{j}(1:3),'Bla'))
            sensNo(n)=j;
            sensName{n}=SenObj.description{j};
            n=n+1;
        end
    end
end


% Reads .sta files and extracts mean torsion values for all seeds
for i=1:length(file)
    [tmp] = LAC.vts.convert(fullfile(simdir, ['STA\', file(i).name]), 'STA');
    for j=1:length(sensNo)
        torsion(i,j) = tmp.mean(sensNo(j),1);
        % For the last seed extract the radii and save
        if i== length(file)
            Rad = sensName{j};
            Index = strfind(Rad,',');
            Radius(j) = str2num(Rad(Index+1:end-2));
        end
    end
end

% Mean of the seeds and creation of results matrix
if size(torsion,1)>1
    tors = mean(torsion);
else
    tors = torsion;
end

T = [Radius' tors'];
% Construction of the .txt file
fileID = fopen(fullfile(outPath,'TorsionTable.txt'),'w');
fprintf(fileID,'%10s %13s\n','Radius [m]','Torsion [deg]');
fprintf(fileID,'%10.3f %13.5f\r\n',T');
fclose(fileID);
end

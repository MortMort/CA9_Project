function LoadCaseWriter(VTSprepfile,idleflag,standstillpitch,varargin)
% Writing load cases for standstill stability evaluations.
% Possible to specify additional variables in optional order. 
% USAGE: LOADCASEWRITER(VTStextfile,idleflag,standstillpitch,'windspeeds',10:5:25,'pitch_misalignment',[95],'azimuths',[0:30:90],'winddirs',[0:10:350]','TI',0.01,'Vexp',0,'randSeed',idleflag)
% If nothing is specified, default values are used.

%% Default settings & definitions
windspeeds = [10:5:25];
azimuths = [0:30:90];
winddirs = [0:10:350];
TI = 0.01;
Vexp = 0;
randSeed = 0;
pitch_misalignment = standstillpitch(1);
 
if(nargin > 3)
    while ~isempty(varargin)
      switch lower(varargin{1})
          case 'windspeeds'
              windspeeds = varargin{2};
              varargin = varargin(3:end);
          case 'azimuths'
              azimuths = varargin{2};
              varargin = varargin(3:end);
          case 'winddirs'
              winddirs = varargin{2};
              varargin = varargin(3:end);
          case 'pitch_misalignment'
              pitch_misalignment = varargin{2};
              varargin = varargin(3:end);
          case 'ti'
              ti = varargin{2};
              varargin = varargin(3:end);
          case 'vexp'
              vexp = varargin{2};
              varargin = varargin(3:end);
          case 'randseed'
              randSeed = varargin{2};
              varargin = varargin(3:end);
          otherwise
              error(['Unknown input option: ' varargin{1}])
      end         
    end
end

% Reset random generator to be able to recreate the same prepfile
rng(randSeed);

%% Load case writer
% generate a temp file name to write on the local disk (faster)
tmpFileName = tempname;
copyfile(VTSprepfile,tmpFileName);
fid=fopen(tmpFileName,'A+t');

fseek(fid,0,1);
if    length(standstillpitch)<3
    standstillpitch = [standstillpitch(1),standstillpitch(1),standstillpitch(1)];
end

for wsp=windspeeds
    for mis=pitch_misalignment
        for az=azimuths
            for wd=winddirs
                if idleflag
                    fprintf(fid,['61SSSidle_ws' num2str(wsp) 'mis' int2str(mis) 'az' int2str(az) 'wd' int2str(wd) '\n']);
                    fprintf(fid,['ntm ',num2str(randi(8,1,1)),' Freq 0 \n']);
                    fprintf(fid,['0.1 0 ' num2str(wsp) ' ' int2str(wd) ' azim0 ' int2str(az) ...
                        ' pitch0 9999 ' num2str(standstillpitch(1)) ' ' num2str(mis) ' ' num2str(standstillpitch(3)) ...
                        ' turb ' num2str(TI) ' Vexp 0.0 time 0.0100 600.0 10.0 60.0 Profdat STANDSTILL \n\n']);
                else
                    fprintf(fid,['61SSSlock_ws' num2str(wsp) 'mis' int2str(mis) 'az' int2str(az) 'wd' int2str(wd) '\n']);
                    fprintf(fid,['ntm ',num2str(randi(8,1,1)),' Freq 0 \n']);
                    fprintf(fid,['0.0 0 ' num2str(wsp) ' ' int2str(wd) ' azim0 ' int2str(az) ...
                        ' pitch0 9999 ' num2str(standstillpitch(1)) ' ' num2str(mis) ' ' num2str(standstillpitch(3)) ...
                        ' turb ' num2str(TI) ' Vexp 0.0 time 0.0100 600.0 10.0 60.0 Profdat STANDSTILL drtdyn 0 1 1 0 1\n\n']); 
                end
            end
        end
    end
end
fclose(fid);
copyfile(tmpFileName,VTSprepfile);
delete(tmpFileName);
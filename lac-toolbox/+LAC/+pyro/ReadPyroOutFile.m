function Output = ReadPyroOutFile(Filename)
%% Extract info from out file
% Overview (operational) matrix

% Supported header format of the overview table (operational table):
%   vind|[wind]   lambda   tipspeed|[tiphast]|[tip_speed]   rotor   generator|[gen.]   pitch   CP(aero)|[CP(aero.)]   CT   a   P(aero)|[P(aero.)]   thrust|[Thrust]   P(gen)|[P(gen.)]   dP/dTheta   geartab|[Loss(gear)]   generatortab|[Loss(gen)|[Loss(gen.)]   andre_tab|[other_tab]|[Loss(aux)]   P(10min.)     CP(el.)   thrust(10min.)|[Thrust(10min.)]   CT(10min.)   LWA|[Noise(LWA)]

[M, WspRows, ColNames, ColUnits] = ReadOperationalTable(Filename);

%% Angle of attack 3d lookup
% Read 3d lookup table:
% Table data       - angle of attack [deg]
% Rows dimension   - rotor radius from root [m]
% Column dimension - wind speed [m/s]
% PESEG 201209 corrected 
%[AoA, Row1_Radius] = LAC.pyro.ReadAero3dLookUp(Filename, 'AoA-mat', false, WspRows); 
[AoA, Row1_Radius] = LAC.pyro.ReadAero3dLookUp(Filename, 'AoA-mat', WspRows);

%% CL matrix
CL = LAC.pyro.ReadAero3dLookUp(Filename, 'CL-mat', WspRows);

%% CD matrix
CD = LAC.pyro.ReadAero3dLookUp(Filename, 'CD-mat', WspRows);

%% CM matrix
CM = LAC.pyro.ReadAero3dLookUp(Filename, 'CM-mat', WspRows);

%% CP matrix
CP = LAC.pyro.ReadAero3dLookUp(Filename, 'CP-mat', WspRows);

%% CT matrix
CT = LAC.pyro.ReadAero3dLookUp(Filename, 'CT-mat', WspRows);

%% a matrix
a1 = LAC.pyro.ReadAero3dLookUp(Filename, 'A1-mat', WspRows);

%% a' matrix
a2 = LAC.pyro.ReadAero3dLookUp(Filename, 'A2-mat', WspRows);

%% v matrix
v = LAC.pyro.ReadAero3dLookUp(Filename, 'V-mat', WspRows);

%% CP-table
% Read 3d lookup table: 
% Table data       - Coeffcient of power [-]
% Rows dimension   - lambda, i.e. blade tip speed [m/s]
% Column dimension - theta, i.e. blade pitch angle [rad]
[Cp_table, Lambda, Theta, ThetaEndCol] = LAC.pyro.ReadAero3dLookUp(Filename, 'CP-tab');

%% CT-table
Ct_table = LAC.pyro.ReadAero3dLookUp(Filename, 'CT-tab', ThetaEndCol);

%% AoA-table
AoA_table = LAC.pyro.ReadAero3dLookUp(Filename, 'AoA-tab', ThetaEndCol);

%% VRel-table
VRel_table = LAC.pyro.ReadAero3dLookUp(Filename, 'VRel-table under', ThetaEndCol);
%% AEP
AEP = LAC.pyro.ReadAero3dLookUp(Filename, 'AEP',0);

%% cpaeromax
cpaeromax = LAC.pyro.ReadAero3dLookUp(Filename, 'cpaeromax',0);


%% PhiOpt
Phiopt = LAC.pyro.ReadAero3dLookUp(Filename, 'Phiopt',0);


%% TSRopt
TSRopt = LAC.pyro.ReadAero3dLookUp(Filename, 'TSRopt',0);

%% Output
Output.NormalOperation.Values = M;
Output.NormalOperation.Names = ColNames';
Output.NormalOperation.Units = ColUnits';
if exist('Row1_Radius','var')
    Output.Row_1_Radius = Row1_Radius;
end
Output.Col_1_Wsp = M(:,1);
if exist('AoA','var')
    Output.AoA_1 = AoA;
end
Output.CL_1 = CL;
Output.CD_1 = CD;
Output.CP_1 = CP;
Output.CT_1 = CT;
Output.CM_1 = CM;
Output.a1_1 = a1;
Output.a2_1 = a2;
Output.v_1 = v;
Output.Row_2_Lambda = Lambda;
Output.Col_2_Theta = Theta;
Output.Cp_table_2 = Cp_table;
Output.Ct_table_2 = Ct_table;
Output.AoA_table_2 = AoA_table;
Output.VRel_table_2 = VRel_table;
Output.AEP = AEP;
Output.cpaeromax = cpaeromax;
Output.TSRopt = TSRopt;
Output.Phiopt = Phiopt;
end

function [Table, WspRows, ColNames, ColUnits] = ReadOperationalTable(Filename)
% Input: 
%   Filename  - File containing operation table.
%
% Output: 
%   Table     - Operational table.
%   WspRows   - Number of wind speed rows.
%   ColNames  - Names of columns.
%   ColUnits  - Unit names.

% Create header format string:
%   supported header formats: (ignoring white spaces)
%   vind|wind   lambda   tipspeed|tip_speed   rotor   generator|gen.   pitch   CP(aero.)|CP(aero)   CT   a   P(aero.)|P(aero)   thrust|Thrust   P(gen.)|P(gen)   dP/dTheta   geartab|Loss(gear)   generatortab|Loss(gen)   other_tab|Loss(aux)   P(10min.)   CP(el.)   thrust(10min.)|Thrust(10min.)   CT(10min.)   LWA|Noise(LWA)'
headerString = sprintf('%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s', ...
    '(vind|wind)\s+', ...
    'lambda\s+', ...
    '(tipspeed|tiphast|tiphast.|tip\_speed)\s+',...
    'rotor\s+',...
    '(generator|gen\.)\s+',...
    'pitch\s+',...
    'CP\((aero|aero\.)\)\s+',...
    'CT\s+',...
    'a\s+',...
    'P\((aero|aero\.)\)\s+',...
    '(thrust|Thrust)\s+',...
    'P\((gen|gen\.)\)\s+',...
    'dP/dTheta\s+',...
    '(geartab|Loss\(gear\))\s+',...
    '(generatortab|Loss\((gen|gen\.)\))\s+',...
    '((andre|other)_tab|Loss\(aux\))\s+',...
    'P\(10min\.\)\s+',...
    'CP\(el.\)\s+',...
    '(thrust|Thrust)\(10min.\)\s+',...
    'CT\(10min\.\)\s+', ...
    'LWA|Noise\(LWA\)');

if exist(Filename, 'file')
    Fid=fopen(Filename);
else
    error(['File does not exist:' Filename]);
end
nline=1;
StartLine = NaN;
EndLine = NaN;
while ~feof(Fid)
    tline = fgetl(Fid);
    nline = nline+1;

    % Check if the current line is the header line.
    headerStringStartIndex = regexp(tline,headerString,'once');
    
    if ~isempty(headerStringStartIndex)
        StartLine = nline;
        ColNamesStr = tline;
        % Read the line with units which is just one line below the header line.
        tline = fgetl(Fid);
        nline = nline+1;
        ColUnitsStr = tline;        
    end
    
    if ~isnan(StartLine)
        if isempty(tline) == 1
            EndLine = nline;
            break
        end
    end
end

fclose(Fid);

if isnan(StartLine) || isnan(EndLine)
    Table = [];
else
    StartRow = StartLine;
    EndRow = EndLine-3;
    WspRows = EndRow-StartRow+1;
    Table = dlmread(Filename,'',[StartRow 0 EndRow 20]);
end

ColNames = textscan(ColNamesStr,'%s');
ColNames = ColNames{:};
ColUnits = textscan(ColUnitsStr,'%s');
ColUnits = ColUnits{:};

end
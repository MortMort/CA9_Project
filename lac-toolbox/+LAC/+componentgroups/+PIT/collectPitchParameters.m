function Hydr = collectPitchParameters(parameterfile,varargin)
% Hydr = collectPitchParameters(parameterfile)
% Script to collect parameters from the pitch system using the input file
% Pitch Geometry Parameters.xlsx, that can be found in DMS 0041-2425
% NIWJO 2021
%

% Input handle and default values
selection1 = '';
selection2 = '';
uselistdlg1 = 0;
uselistdlg2 = 0;

while ~isempty(varargin)
    switch lower(varargin{1})
        case 'selection1'
            selection1            = varargin{2};
            varargin(1:2) = [];
        case 'selection2'
            selection2            = varargin{2};
            varargin(1:2) = [];
        otherwise
            error(['Unexpected option: ' varargin{1}])
    end
end

[~,~,RAW1] =   xlsread(parameterfile,'PitchGeo','A15:G50');
for i = 1:size(RAW1,1)
    if isnan(RAW1{i,1})
        break
    end
    data1(i).name = regexprep(RAW1{i,1},'\n','');
    data1(i).R = RAW1{i,2};
    data1(i).Xa = RAW1{i,3};
    data1(i).Ya = RAW1{i,4};
    data1(i).k = RAW1{i,5};
    data1(i).Pdz = RAW1{i,6};
    data1(i).x_stroke = RAW1{i,7};
end

%%
[~,~,RAW2] =   xlsread(parameterfile, 3,'B3:U50');

for i = 1:size(RAW2,1)
    if any(strfind(RAW2{i,1},'Description'))
        break
    end
    turbine{i}                      = RAW2{i,1};
    data2(i).d_rod      			= RAW2{i,17};           % Rod diameter [m]
    data2(i).d_piston   			= RAW2{i,11};           % Piston diameter [m]
    data2(i).effectiveVolAcc 		= RAW2{i,2}*1e-3; 			% Accumulator - eff. volumen [m3]
    data2(i).preChargePressureAcc   = 110e5; 			% Pre-charge pressure [Pa]
    data2(i).Orifice1_Diameter      = RAW2{i,8};				% Safety Pitch Orifice1 [mm]
    data2(i).Orifice2_Diameter      = RAW2{i,9}; 				% Safety Pitch Orifice2 [mm]
    data2(i).PitchSpeedHigh 		= RAW2{i,14}; 			% Safety Pitch Speed High [deg/s]
    data2(i).PitchSpeedLow          = RAW2{i,15}; 			% Safety Pitch Speed Low [deg/s]
    data2(i).PiMax                  = 95; 				% Maximum pitching angle before lock [deg]
end

% Only output the selected variants
if isempty(selection1)
    uselistdlg1 = 1;
elseif ~any(strcmpi({data1.name},selection1))
    warning('Selection not found in file')
    uselistdlg1 = 1;
else
    indx = strcmpi({data1.name},selection1);
end
if uselistdlg1
    indx = listdlg('PromptString','Select turbine for geometry parameters',...
        'SelectionMode','single',...
        'ListString',{data1.name});
    disp(['Selection 1 = "' data1(indx).name '"'])
end

if isempty(selection2)
    uselistdlg2 = 1;
elseif ~any(strcmpi(turbine,selection2))
    warning('Selection not found in file')
    uselistdlg2 = 1;
else
    indx2 = strcmpi(turbine,selection2);
end

if uselistdlg2
    indx2 = listdlg('PromptString','Select turbine for geometry parameters',...
        'SelectionMode','single',...
        'ListString',turbine);
    disp(['Selection 2 = "' turbine{indx2} '"'])
end
Hydr = cell2struct([struct2cell(data1(indx)); struct2cell(data2(indx2))],[fieldnames(data1(indx)); fieldnames(data2(indx2))]);

% Fix wird names
Hydr.name = regexprep(Hydr.name,{'\s+',':',',','"','*','-'},{'_','','','','','_'});

% Small Cal and corrections
% Geometry Related
if Hydr.Ya==0 % if Hydr.Ya = 0 then its assuming dual cylinder setup
    nrCyl = 2;
else
    nrCyl = 1;
end
Hydr.Ap         = Hydr.d_piston^2*pi/4*nrCyl;             % Piston side area [m2]
Hydr.Ar         = Hydr.Ap-Hydr.d_rod^2*pi/4*nrCyl;        % Rod side area [m2]
Hydr.Aregen          = Hydr.d_rod^2*pi/4*nrCyl;                % Rod area which is equal to Hydr.Ap-Hydr.Ar. This is the effective area for flow calculation doing normal operation

Hydr.AO              = sqrt(Hydr.Ya^2+Hydr.Xa^2);        % Length from cylinder fasten point to blade center [m]
Hydr.alpha_min       = acos((Hydr.AO^2+Hydr.R^2-Hydr.k^2)/(2*Hydr.R*Hydr.AO)); % [rad]
if Hydr.Ya==0 % if Hydr.Ya = 0 then its assuming dual cylinder setup
    Hydr.gamma           = 90*pi/180;
else
    Hydr.gamma           = acos((Hydr.AO^2+Hydr.Ya^2-Hydr.Xa^2)/(2*abs(Hydr.Ya)*Hydr.AO));
end
Hydr.alpha0_vts      = Hydr.alpha_min + Hydr.gamma - Hydr.Pdz;

% Legacy poly calc for VTS
x               = linspace(0,Hydr.x_stroke,100); % m
theta           = acos((Hydr.AO^2+Hydr.R^2-(Hydr.k+x).^2)./(2*Hydr.AO*Hydr.R))-Hydr.alpha_min+Hydr.Pdz;
Hydr.pcell      = polyfit(x*1e3,rad2deg(theta),4);
end
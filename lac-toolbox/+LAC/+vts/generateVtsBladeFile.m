function [out_struct] = generateVtsBladeFile(fnFlxExp,fnBldIn,fnBldOut,fnProps,varargin)

% Script to generate a VTS BLD file from:
%  - a FlexExport file received from Blade department
%  - a input BLD file used for the parameters not defined in the FlexExport
%  file (root coning, mass factors etc.)

% History
%  - V00: DACA, 06/05/2015. Not reviewed
%  - V??: MISVE, many intermediate changes, probably reviewed at some point 
%  - V01: MISVE, Added support for using new flex export file format 
%..- V02: HACIE, Added new functionalities. Backward compatibility maintained. 
%                New functionalites: Shear correction, standard output sensors and set PhiOut(1)=0.

if nargin < 1
    [flxExpFileName,flxExpPathName] = uigetfile('*.csv','Select the FlexExport.csv file');
    fnFlxExp     = fullfile(flxExpPathName,flxExpFileName);
end
%Get properties from the flex export file. The number of parameters/properties
%determines which flex export file version it is. 
objFlxExp = LAC.vts.convert(fnFlxExp,'BLD_FLXEXP');

BladeVersion = 0; %Original version with 16 properties, the rest should be in the static props file
optionArgNum = 4; %Which argument number contains the additional optons (varargin)
if(length(objFlxExp.SectionTable.parameters) == 26) %Flx export version with 26 parameters
    BladeVersion = 1;
    optionArgNum = 3; %There should be no static props file
    if nargin > 3
    varargin = [{fnProps} varargin]; %add the fnProps to varargin argument
    end
end

%Get additional parameters if not specified in input
pathName = fileparts(objFlxExp.filename);
if nargin<optionArgNum
    if nargin < 3
        if nargin < 2
            [bldInFileName,bldInPathName]   = uigetfile('*.*'  ,'Select the BLD file used as input/template',pathName);
            fnBldIn      = fullfile(bldInPathName,bldInFileName);
        end
        [bldOutFileName,bldOutPathName] = uiputfile('*.*'  ,'Path to save new BLD file',pathName);
        fnBldOut     = fullfile(bldOutPathName,bldOutFileName);
    end
    if(BladeVersion == 0)
        [propsFileName,propsPathName]   = uigetfile('*.csv','Select the StaticProps.csv file',pathName);
        fnProps      = fullfile(propsPathName,propsFileName);
    end
end

%Get properties from input blade
objBldIn  = LAC.vts.convert(fnBldIn, 'BLD');
if(BladeVersion == 0)
    objProps  = LAC.vts.convert(fnProps, 'BLD_PROPS');
end
objBldOut = LAC.vts.convert(fnBldIn, 'BLD');

% Replace section table to FlexExport data
objBldOut.SectionTable   = objFlxExp.SectionTable;
objBldOut.SectionTable.UE0 = -objBldOut.SectionTable.UE0; % x-axis should be positive towards LE (WiC tools are positive towards TE).
warning('In LAC.vts.generateVtsBladeFile:\nThe sign of UE0 in FlexExport has been changed to comply with the VTS sign convention for UE0.',...
    'off','backtrace');
objBldOut.nCrossSections = length(objBldOut.SectionTable.R);

% Use input parser object to allow for optional parameters with default
% values. The purpose is to be able to specify programatically what options
% to choose instead of being prompted with interactive questions.
Parser = inputParser;
Parser.addOptional('AddRoot','None'); % None = use the interactive dialog.
Parser.addOptional('PrincAxis','None');
Parser.addOptional('ChangeLastSection','None');
Parser.addOptional('OutputsSameAsInputBLD','None');
Parser.addOptional('PrebendSameAsInputBLD','None');
Parser.addOptional('rotorDiameter','None');
Parser.addOptional('commentString','None');
Parser.addOptional('skipWarning',false);
Parser.addOptional('profile_data_production','');
Parser.addOptional('profile_data_standstill','');
Parser.addOptional('GammaRootEdge',false);
Parser.addOptional('ApplyShearCorrection',[]);
Parser.addOptional('Set_root_PhiOut_to_zero','dialog');
Parser.addOptional('comments',false);

% Parse.
Parser.parse(varargin{:});

% Set variables.
RootPhiOutCorrection = Parser.Results.('Set_root_PhiOut_to_zero');
ApplyShearCorrection = Parser.Results.('ApplyShearCorrection');
InAddRoot = Parser.Results.('AddRoot');
InPrincAxis = Parser.Results.('PrincAxis');
InChangeLastSection= Parser.Results.('ChangeLastSection');
InOutputsSameAsInputBLD = Parser.Results.('OutputsSameAsInputBLD');
InPrebendSameAsInputBLD = Parser.Results.('PrebendSameAsInputBLD');
InrotorDiameter = Parser.Results.('rotorDiameter');
IncommentString = Parser.Results.('commentString');
skipWarning = Parser.Results.('skipWarning');
profile_data_production = Parser.Results.('profile_data_production');
profile_data_standstill = Parser.Results.('profile_data_standstill');
GammaRootEdge = Parser.Results.('GammaRootEdge');
comments = Parser.Results.('comments');

%%
% Add section at root
if strcmp(InAddRoot,'Yes') || strcmp(InAddRoot,'No')
    Flag.AddRoot = InAddRoot;
else
    Flag.AddRoot = questdlg(['In FlexExport file, the first 2 sections are at radius ', num2str(objBldOut.SectionTable.R(1),'%.2f'), ' and ', num2str(objBldOut.SectionTable.R(2),'%.2f'),...
        '. Do you want to add a section at ' num2str(objBldOut.SectionTable.R(1)+0.01,'%.2f') ' and make first section output angle 0?'], ...
        'Extra section at blade root.', ...
        'No','Yes','Yes');
end

if isempty(ApplyShearCorrection)
   answer = questdlg('Do you want to apply shear correction using the ''LAC.vts.apply_BLD_correction'' function?','Shear correction',...
        'No','Yes','Yes');
    switch answer
        case 'No'
          ApplyShearCorrection = false;
        case 'Yes'
          ApplyShearCorrection = true;
    end
end

if strcmp(Flag.AddRoot,'Yes')
        if isempty(find(objBldOut.SectionTable.R==objBldOut.SectionTable.R(1)+0.01,1))
            secDat = objBldOut.addSection(objBldOut.SectionTable.R(1)+0.01,objBldOut.SectionTable.Out{1});
            objBldOut.SectionTable   = secDat.SectionTable;
            objBldOut.nCrossSections = secDat.nCrossSections;
        end
        objBldOut.SectionTable.PhiOut(1) = 0;
end


% Do principal axis correction if requested
if strcmp(InPrincAxis,'Yes') || strcmp(InPrincAxis ,'No')
    Flag.PrincAxis = InPrincAxis;
else
    Flag.PrincAxis = questdlg('Do you want to include principal axis correction?','Principal axis correction',...
        'No','Yes','Yes');
end

if BladeVersion == 0
    if strcmp(Flag.PrincAxis,'Yes')
        % First check that EIFlap and EIEdge from FlexEport match values from StaticProps
        EIFlapDiff = objBldOut.SectionTable.EI_Flap - interp1(objProps.Struct.R,objProps.Struct.EI_flap,objBldOut.SectionTable.R);
        EIEdgeDiff = objBldOut.SectionTable.EI_Edge - interp1(objProps.Struct.R,objProps.Struct.EI_edge,objBldOut.SectionTable.R);

        objBldOut.SectionTable.p_ang       = objBldOut.SectionTable.beta + interp1(objProps.Struct.R,objProps.Struct.p_ang,objBldOut.SectionTable.R)-90;
        objBldOut.SectionTable.EI_Edge     = interp1(objProps.Struct.R,objProps.Struct.EI_1,objBldOut.SectionTable.R);
        objBldOut.SectionTable.EI_Flap     = interp1(objProps.Struct.R,objProps.Struct.EI_2,objBldOut.SectionTable.R); 
        objBldOut.SectionTableNrOfFields   = 17;

        if max(abs(EIFlapDiff))>0
            Flag.EIFlap = questdlg('There is difference between EIFlap from your FlexExport file and your StaticProps file.\n\nWhich value should be usedfor EI Flap?', ...
                                    'EI Flap', ...
                                    'FLEX EXPORT','STATIC PROPS','FLEX EXPORT');

            if strcmp(Flag.EIFlap,'FLEX EXPORT')
                objBldOut.SectionTable.EI_Flap     = interp1(objFlxExp.Struct.R,objFlxExp.Struct.EI_Flap,objBldOut.SectionTable.R);            
            end

        end
        if max(abs(EIEdgeDiff))>0
            Flag.EIEdge = questdlg('There is difference between EIEdge from your FlexExport file and your StaticProps file.\n\nWhich value should be usedfor EI Flap?', ...
                                    'EI Flap', ...
                                    'FLEX EXPORT','STATIC PROPS','FLEX EXPORT');

            if strcmp(Flag.EIEdge,'FLEX EXPORT')
                objBldOut.SectionTable.EI_Edge     = interp1(objFlxExp.SectionTable.R,objFlxExp.SectionTable.EI_Edge,objBldOut.SectionTable.R);     
            end        
        end   
    end
end

if BladeVersion == 1
    if strcmp(Flag.PrincAxis,'Yes')
        objBldOut.SectionTable.p_ang       = objBldOut.SectionTable.beta + objBldOut.SectionTable.p_ang-90;
        objBldOut.SectionTable.EI_Edge     = objBldOut.SectionTable.EI_1;
        objBldOut.SectionTable.EI_Flap     = objBldOut.SectionTable.EI_2; 
        objBldOut.SectionTableNrOfFields   = 17;
    end
end

% Rotor Diameter
if ~strcmp(InrotorDiameter,'None')
    rotorDiameter = InrotorDiameter;
else
    rotorDiameter = inputdlg('Rotor diameter:','Rotor diameter',[1 20]);
    rotorDiameter = str2double(rotorDiameter);
end

% Change last section radius if it does not match the correct radius
if objBldOut.SectionTable.R(end)~=rotorDiameter/2
    if strcmp(InChangeLastSection,'Yes') || strcmp(InChangeLastSection,'No')
        ChangeLastSection.flag = InChangeLastSection;
    else
        ChangeLastSection.flag = questdlg(['In FlexExport file, the last section is defined at radius ', num2str(objBldOut.SectionTable.R(end),'%.2f'), ' which does not match the rotor diameter of ',...
            num2str(rotorDiameter,'%.2f'),'. Do you want to change radius of last section to match the rotor diameter?'], ...
            'Radius of last section.', ...
            'No','Yes','Yes');
    end
    if strcmp(ChangeLastSection.flag,'Yes')
        objBldOut.SectionTable.R(end) = rotorDiameter/2;
    end
end

% Outputs
if ~strcmp(InOutputsSameAsInputBLD,'None')
    Flag.Outputs = InOutputsSameAsInputBLD;
else
    options = {'Same as input BLD','Only 0','Standard output','Extended output','FlexExport and vts'};
            selection = listdlg('PromptString','Which outputs should be added?',...
                'SelectionMode','single',...
                'ListString',options,'ListSize',[200 100],'Name','Outputs.');
           Flag.Outputs =  options{selection};
end

switch Flag.Outputs
    case 'Same as input BLD'
        for i=1:length(objBldOut.SectionTable.R)
            index = find(objBldIn.SectionTable.R == objBldOut.SectionTable.R(i));
            if ~isempty(index)
                objBldOut.SectionTable.Out(i)      = objBldIn.SectionTable.Out(index);
            else
                objBldOut.SectionTable.Out(i) = {'0'};
            end
        end
    case {'Only 0','No output'}
        Flag.Outputs = 'No output';
        objBldOut = objBldOut.setStandardOutputSensors(Flag.Outputs);
    case 'Standard output'        
        objBldOut = objBldOut.setStandardOutputSensors(Flag.Outputs);
    case 'Extended output'
        objBldOut = objBldOut.setStandardOutputSensors(Flag.Outputs);
    case 'FlexExport and vts'
        objBldOut = objBldOut.setStandardOutputSensors('Add noise sensors'); % AoA for noise
        objBldOut = objBldOut.setStandardOutputSensors('Add IntPostD interpolation sensors');
        objBldOut.SectionTable.Out{1} = '6.123'; % All forces/moments at root
        objBldOut.SectionTable.Out{end} = '6.123 aoa cl cd cm torsion';
    otherwise
        % No change = same as FlexExport
end

% Prebend
if ~strcmp(InPrebendSameAsInputBLD,'None')
    Flag.Prebend = InPrebendSameAsInputBLD;
else
    Flag.Prebend = questdlg(['Which prebend and blade root coning should be used?'], ...
        'Prebend.', ...
        'Same as input BLD','Same as FlexExport','Only 0','Same as input BLD');
end

switch Flag.Prebend
    case 'Same as input BLD'
        % Blade root coning already from Input file
        NormRadius.Input  = (objBldIn.SectionTable.R-objBldIn.SectionTable.R(1))/(objBldIn.SectionTable.R(end)-objBldIn.SectionTable.R(1));
        NormRadius.Output = (objBldOut.SectionTable.R-objBldOut.SectionTable.R(1))/(objBldOut.SectionTable.R(end)-objBldOut.SectionTable.R(1));
        objBldOut.SectionTable.UF0 = interp1(NormRadius.Input,objBldIn.SectionTable.UF0,NormRadius.Output);
        objBldOut.SectionTable.UE0 = interp1(NormRadius.Input,objBldIn.SectionTable.UE0,NormRadius.Output);
    case 'Same as FlexExport'
        % UF0 and UE0 already Ok.
        objBldOut.GammaRootEdge = objBldIn.GammaRootEdge;
        objBldOut.GammaRootFlap = objBldIn.GammaRootFlap;
    case 'Only 0'
        objBldOut.SectionTable.UF0 = zeros(size(objBldOut.SectionTable.UF0));
        objBldOut.SectionTable.UE0 = zeros(size(objBldOut.SectionTable.UE0));
        objBldOut.GammaRootEdge = 0;
        objBldOut.GammaRootFlap = 0;
end

if ~strcmp(IncommentString,'None')
    commentString = IncommentString;
else
    commentString = inputdlg({'Blade name','Comments'},'Blade name and comments',[1 100; 1 100],{['V',num2str(rotorDiameter,'%i')],[date, ' Created from ' fnFlxExp ' and ' fnBldIn]});
end

objBldOut.bladeName = commentString{1};
if ischar(commentString{2})
    objBldOut.comments  = {commentString{2}};
else
    objBldOut.comments  = commentString{2};
end

% Override data if specified.
if ~strcmp(profile_data_production, '');
    objBldOut.ProfileData.DEFAULT = profile_data_production;
end
if ~strcmp(profile_data_standstill, '');
    objBldOut.ProfileData.STANDSTILL = profile_data_standstill;
end
if isa(comments, 'cell');
    objBldOut.comments = comments;
end
if isa(GammaRootEdge, 'double');
    objBldOut.GammaRootEdge = GammaRootEdge;
end

% Setting tip flap and edge stiffness to (almost) zero.
if objBldOut.SectionTable.EI_Flap(end) == 0
    objBldOut.SectionTable.EI_Flap(end)=0.01;
end
if objBldOut.SectionTable.EI_Edge(end) == 0
    objBldOut.SectionTable.EI_Edge(end)=0.01;
end

% Setting PhiOut=0 at root.
if objBldOut.SectionTable.PhiOut(1) ~= 0
    switch RootPhiOutCorrection
        case 'dialog'
            answer = questdlg(sprintf('PhiOut(1)=%1.3f. Do you want to set PhiOut(1)=0 at root?',objBldOut.SectionTable.PhiOut(1)),'Root PhiOut correction',...
            'No','Yes','Yes');
            if strcmp(answer,'Yes')
                fprintf('Setting PhiOut=0 at root ...\n')
                objBldOut.SectionTable.PhiOut(1)=0;
            end
        case true
            fprintf('Setting PhiOut=0 at root ...\n')
            objBldOut.SectionTable.PhiOut(1)=0;    
    end
end

%% Write file
objBldOut.encode(fnBldOut)

% Apply Shear Correction
if ApplyShearCorrection
    fprintf('Applying shear correction ...\n')
    LAC.vts.apply_BLD_correction(fnBldOut,false);
    objBldOut = LAC.vts.convert(fnBldOut, 'BLD');
end

%% Check blade file
% disp('Checking blade file:');
% retval = system(['w:\SOURCE\BLDFileCheck.exe ' fnBldOut]);
% if(retval ~= 0)
%     error('Blade file check failed. Something is wrong with the generated blade')
% end


%% Warning
if ~skipWarning
    message = {'BLD file created';'Remember to check that it''s correct, especially profile files, structural damping, prebend and cone/tilt/blade root angles';'Please report any bugs or suggestion for improvement to MAARD'};
    warndlg(message)
end

% Set output in a structure so that we have freedom to add more outputs without changing the calling syntax.
out_struct.objBldOut = objBldOut;
out_struct.objBldIn = objBldIn;
end
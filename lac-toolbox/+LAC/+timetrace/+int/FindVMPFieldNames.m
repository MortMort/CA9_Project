function [nofield, symfield] = FindVMPFieldNames(geninfo, stdsenscfg, turbineconcept);
% Find relevant field names in StdSensCfg struct.
% 
% Based on:
% 
% - processor type ('CT5000.02' or 'CT6000') 
% - SW-release found in geninfo.Release
% 
% JEB 23/12 2003


% find first part of the 'nofield' and 'symfield' names   
switch geninfo.Processor
    case 'CT5000.02'
        switch turbineconcept
            case 'VCS'
                StringBeginning = 'VCS_VDF5000_02';
            case 'VRCC'
                StringBeginning = 'VRCC_VDF5000_02';
        end
    case 'CT6000'
        StringBeginning = 'VDF6000';
end
    

%** lav addition af tekst afh. af turbine concept VRCC_VDF5000_02 No ***
%** lav det om således at vmp5000.02 vrcc ikke læses fra vmp3500
% find a cell array with all fields numbers starting with the string in StringBeginning
StdSensCfgFields = fieldnames(stdsenscfg);
FieldNo2Search = strmatch(StringBeginning,StdSensCfgFields); % vector with positions
Fields2Search = sort(StdSensCfgFields(FieldNo2Search)); % in alphabetical order, which also means sorted according to sw-release

Count=0; % counter

% search through the strings in the field array 'Fields2Search'
% to first find out which sw-releases are present in the stdsenscfg.mat file
for n=1:length(Fields2Search)
    FieldString = Fields2Search{n};
    if strmatch('No',FieldString(end-1:end),'exact')  % only look at fields with 'No' last in their field name
        Count=Count+1;
        % SW-release is after the 'VMPRel' part of the string (if it exists) and the 'No' part of the string
        VMPRel_Pos = findstr('VMPRel',FieldString);
        if isempty(VMPRel_Pos) % this is the case for 'VDF6000No' and 'VDF5000_02No'
            SWrel(Count)=0;
        else
            SWrel(Count) = str2double(FieldString(VMPRel_Pos + length('VMPRel'):end-2)); % last 2 characters are 'No'
        end
    end
end

VMPSWRelIsModified=0; % initilisation
if geninfo.Release<1000 % then the release is e.g. header.Release=205 and not e.g. 20434 Note the release cannot have 4 digits
    % modify the header.Release number because the field names in the stdsensdef.mat assume 5 digits
    geninfo.Release=geninfo.Release*100; 
    VMPSWRelIsModified=1; 
end

% next, find out which sw-release name (in stdsenscfg) that should be used based on the sw-release in geninfo
for n=1:length(SWrel)
    if SWrel(n)<=geninfo.Release
        SWrel2use = SWrel(n);
    end
end

if VMPSWRelIsModified
    % then set it back for it to compatible (correct format)in e.g. FindSysStateDesc.m
    geninfo.Release=geninfo.Release/100;
end


% find the field names
if SWrel2use == 0
    % examples of field names : ('VDF6000No', 'VDF6000Sym') or ('VDF5000_02No', 'VDF5000_02Sym');
    nofield=[StringBeginning 'No'];
    symfield=[StringBeginning 'Sym'];
else
    %  examples of field names :  ('VDF6000_VMPRel30302No', 'VDF6000_VMPRel30302Sym) or 
    %                             ('VDF5000_02_VMPRel50505No', 'VDF5000_02_VMPRel50505Sym)
    nofield=[StringBeginning '_VMPRel' num2str(SWrel2use) 'No'];
    symfield=[StringBeginning '_VMPRel' num2str(SWrel2use) 'Sym'];
end



    
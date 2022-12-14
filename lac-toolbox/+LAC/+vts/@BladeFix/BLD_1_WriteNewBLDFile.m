function BLD_1_WriteNewBLDFile(self)
%BLD_1_WriteNewBLDFile() - Writes the new BLD file 
% with all the necessary corrections. It creates two BLD files: 
% 1 with standard output sensors and 1 with all outputs at every blade station.
newFileContent = self.insertTagsInTemplate(self.inputs.BLDTemplate,self.inputs);
[~,BLDTemplate,extension] = fileparts(self.inputs.BLDTemplate);
newBLD_tplfile = fullfile(self.inputs.OutputFolder,[BLDTemplate '.tpl']);
fileID = fopen(newBLD_tplfile,'w');
for i = 1:size(newFileContent,1)
    fprintf(fileID,'%s\n',newFileContent{i,1});
end
fclose(fileID);

AddRoot = 'Yes';
PrincAxis = 'Yes';
ChangeLastSection = 'Yes';
OutputsSameAsInputBLD = self.inputs.OutputSensors;
PrebendSameAsInputBLD = 'Same as FlexExport';

% creating comment on BLD file
filepath = mfilename('fullpath');
[~,thisFile]=fileparts(filepath);
idx=strfind(filepath,'\');
gitRepositoryPath = filepath(1:idx(end-2));
[~,gitRemoteRepository] = system(sprintf('git -C %s config --get remote.origin.url',gitRepositoryPath));
gitRemoteRepository = regexprep(gitRemoteRepository,[getenv('username') '@'],'');
[~,gitHASH] = system(sprintf('git -C %s rev-parse HEAD',gitRepositoryPath));
BLD = LAC.vts.convert(newBLD_tplfile,'BLD');
commentString{1} = BLD.bladeName;
commentString{2} =  BLD.comments;
commentString{2}{end+1,1} = '';

commentString{2}{end+1,1} = sprintf('%s - File generated using Matlab class ''LAC.vts.BladeFix''',datestr(now, 'yyyymmdd-HH:MM'));
commentString{2}{end+1,1} = sprintf('USER: %s, PC: %s, Matlab version: %s',getenv('username'),getenv('computername'),version);
commentString{2}{end+1,1} = sprintf('Commit HASH: %s at remote Git repository: %s',gitHASH,gitRemoteRepository);



% Call function.
self.newBLDfile = fullfile(self.inputs.OutputFolder, self.inputs.BLDFileName);
self.newBLDfileExtended = fullfile(self.inputs.OutputFolder, self.inputs.BLDFileNameExtended);
out = LAC.vts.generateVtsBladeFile(...
    self.inputs.FlexExportCSV,...
    newBLD_tplfile,...
    self.newBLDfile,...
    'AddRoot',AddRoot,...
    'PrincAxis',PrincAxis,...
    'ChangeLastSection',ChangeLastSection,...
    'OutputsSameAsInputBLD',OutputsSameAsInputBLD,...
    'PrebendSameAsInputBLD',PrebendSameAsInputBLD,...
    'rotorDiameter',self.inputs.RotorDiameter,...
    'commentString', commentString,...
    'skipWarning',true,...
    'ApplyShearCorrection',self.inputs.ShearCenterCorrection);

BLD_extendedOutput = out.objBldOut.setStandardOutputSensors('Extended output');
BLD_extendedOutput.encode(self.newBLDfileExtended);

%delete(newBLD_tplfile);

end

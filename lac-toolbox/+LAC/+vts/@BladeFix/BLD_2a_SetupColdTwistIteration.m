function BLD_2a_SetupColdTwistIteration(self)
%BLD_2a_SetupColdTwistIteration() - Sets up a VTS simulation 
% to determine the hot twist using the current BLD file. It is possible
% run VTS locally directly from the method.
[filepath,prepFileName,extension] = fileparts(self.inputs.PrepFile);
self.twistSimulationFolder = fullfile(self.inputs.OutputFolder,'twistSimulationFolder');
if ~isdir(self.twistSimulationFolder)
    mkdir(self.twistSimulationFolder);
end

copyfile(self.inputs.PrepFile,self.twistSimulationFolder)

if exist(fullfile(filepath,'_CtrlParamChanges.txt')) && ~isempty(self.inputs.OTCfile)
    error('You cannot both specify a OTCfile in the BladeFix_Input.txt and have a _CtrlParamChanges.txt together with the reference prep file.')
end

if ~exist(fullfile(filepath,'_CtrlParamChanges.txt')) && isempty(self.inputs.OTCfile)

answer = questdlg('There was not an .otc reference in BladeFix_Input.txt, nor a _CtrlParamChanges.txt file in the reference prepfile folder. Are you sure you want to continue?', ...
	'BladeFix Menu', ...
	'Yes','No', 'No');
% Handle response
switch answer
    case 'Yes'
       
    case 'No'
        error('Please define either an .otc file in BladeFix_Input.txt or a _CtrlParamChanges.txt')
end
end
   


%disable wind estimator for cold twist iteration
paramWIS={'Px_SelectWindSpdType = 0', 'Px_LDO_HWO_SelectWindSpdEst = 0', 'Px_NRS_UseWindSpdEst = 0', 'Px_OTC_UseWindSpdEst = 0', 'Px_SC_UseWindSpdEst = 0', 'Px_LDO_LaPM_UseWindSpdEst = 0'};

if ~isempty(self.inputs.OTCfile)
    copyfile(self.inputs.OTCfile,fullfile(self.twistSimulationFolder,'_CtrlParamChanges.txt'));
	fid = fopen(fullfile(self.twistSimulationFolder,'_CtrlParamChanges.txt'),'a');
    fprintf(fid,'%s\n', paramWIS{:});
    fclose(fid)
end

if exist(fullfile(filepath,'_CtrlParamChanges.txt'))
   copyfile(fullfile(filepath,'_CtrlParamChanges.txt'),self.twistSimulationFolder);	
   fid = fopen(fullfile(self.twistSimulationFolder,'_CtrlParamChanges.txt'),'a');
   fprintf(fid,'%s\n', paramWIS{:});
   fclose(fid)
end

prepfile = LAC.vts.convert(fullfile(self.twistSimulationFolder,[prepFileName extension]),'REFMODEL');
prepfile.Files('BLD') = self.newBLDfileExtended;

prepfile.comments = '';
prepfile.dlc94loadcases(self.inputs.HotTwistWindSpeed,'1');

prepfile.encode(fullfile(self.twistSimulationFolder,[prepFileName '.txt']));
self.twistIteration = self.twistIteration+1;


if ~isempty(ls(fullfile(self.twistSimulationFolder,'\Loads\STA\',sprintf('94*_%0.1f*.sta',self.inputs.HotTwistWindSpeed))))
    answer1 = questdlg('VTS simulations from previous iteration will be overwrited. Run VTS? (Takes about 4min)','Run VTS simulation?','Yes','No','Yes');
else
    answer1 = 'Yes';
end

if strcmpi(answer1,'Yes')
    fid = fopen(fullfile(self.twistSimulationFolder,'RunBat.bat'),'w');
    fprintf(fid,'start FAT1.bat -R 0110000 -u -c -loads -p %s', fullfile(self.twistSimulationFolder,[prepFileName '.txt']));
    fclose(fid);
    fprintf('Please wait for simulation to finish (approx. 4 min). BladeFix will continue automatically after VTS is done ...\n')
    system(fullfile(self.twistSimulationFolder,'RunBat.bat'));
    pause(180)
    LAC.vts.is_simulation_done(self.twistSimulationFolder,10,0.25);
else
    fprintf('You can run simulation in %s \nto get input to twist correction \n',fullfile(self.twistSimulationFolder,'RunBat.bat'));
end

end


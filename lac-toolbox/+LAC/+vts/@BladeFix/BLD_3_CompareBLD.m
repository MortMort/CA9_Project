function BLD_3_CompareBLD(self)
%BLD_3_CompareBLD() - Compares the properties with the previous blade
% if such a blade exist.
bldNEW = LAC.vts.convert(self.newBLDfile,'BLD');
bldNEW_mass = bldNEW.computeMass;

% Calculate new mfac for DLC 1.2
mfac_ext = LAC.vts.DibtIce(self.newBLDfile,'extreme');
mfac_fat = LAC.vts.DibtIce(self.newBLDfile,'fatigue');
if self.finalBladeReached
	saveFolder = self.finalFolder;
else
	saveFolder = self.inputs.OutputFolder;
end

if ~strcmp(self.inputs.PreviousBlade,'')
    bldOLD = LAC.vts.convert(self.inputs.PreviousBlade,'BLD');
    bldOLD_mass = bldOLD.computeMass;
    
    bldOLD.compareProperties(bldNEW,'relative');
    relative = gcf;
    bldOLD.compareProperties(bldNEW);
    absolute = gcf;

	prompt = {'Filename of relative figure','Filename of absolute figure'};
	dlg_title = 'Save figures?';
	num_lines = 1;
	defaultans = {'Relative_bladeCompare','Absolute_bladeCompare'};
	answer = inputdlg(prompt,dlg_title,num_lines,defaultans);
	if ~isempty(answer)
	    LAC.savefig(relative,answer(1),saveFolder,true);
	    LAC.savefig(absolute,answer(2),saveFolder,true);
	else
		fprintf('figures not saved ...\n')	
    end
    

else
    bldNEW.plotProperties();
    
    prompt = {'Filename of properties figure'};
	dlg_title = 'Save figures?';
	num_lines = 1;
	defaultans = {'bladeProperties'};
	answer = inputdlg(prompt,dlg_title,num_lines,defaultans);
	if ~isempty(answer)
	    LAC.savefig(gcf,answer(1),saveFolder,true);
	else
		fprintf('figure not saved ...\n');
	end

    
end

% print .txt with comparison of masses, and new DLC 1.2 mfac

Mass_Output = fullfile(saveFolder,'MassComparison.txt');
fprintf('Writing mass factor extract to: %s \n',Mass_Output)
fid = fopen(Mass_Output,'w');
fprintf(fid,'Mass comparison: \n');
if ~strcmp(self.inputs.PreviousBlade,'')
    fprintf(fid,sprintf('New mass: %0.2f kg, previously %0.2f kg (%0.3f percent) \n',bldNEW_mass.Mass,bldOLD_mass.Mass,bldNEW_mass.Mass/bldOLD_mass.Mass*100));
    fprintf(fid,sprintf('New smom: %0.2f kgm, previously %0.2f kgm (%0.3f percent) \n',bldNEW_mass.Smom,bldOLD_mass.Smom,bldNEW_mass.Smom/bldOLD_mass.Smom*100));
else
    fprintf(fid,sprintf('New mass: %0.2f kg \n',bldNEW_mass.Mass));
    fprintf(fid,sprintf('New smom: %0.2f kgm \n',bldNEW_mass.Smom));
end
fprintf(fid,'Mass factors for DLC 1.2 from LAC.vts.DibtIce: \n');
fprintf(fid,sprintf('mfac ultimate: %0.3f \n',mfac_ext));
fprintf(fid,sprintf('mfac fatigue: %0.3f \n',mfac_fat));
fclose(fid);
end
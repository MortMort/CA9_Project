function BLD_4_runPyro(self)
%BLD_4_runPyro() - Runs the .inp Pyro file 
% in order to get Cp/Ct tables for the CtrlInput update.
% Updates the path reference to the .out file in the BLD files,
% after running.

% Create .bat file to run pyro
[pathFile, pyro_file_name] = fileparts(self.inputs.AeroInpFile);
batFileName = fullfile(self.inputs.OutputFolder,'Run_pyro.bat');
fileID = fopen(batFileName,'w');

fprintf(fileID,'%s %s\n',self.pyroVersion,self.inputs.AeroInpFile);
fclose(fileID);

% Run the Pyro Model
pyroOutPath = fullfile(pathFile,[pyro_file_name '.out']);
if exist(pyroOutPath,'file')==2
    answer = questdlg('Pyro Output already exists. Would you like to re-RUN pyro now?','RUN Pyro??','Yes','No','No');
    if strcmpi(answer,'No')
        fprintf('Updating .out path in BLD files to %s\n',pyroOutPath);
        BLD_extended = LAC.vts.convert(self.newBLDfileExtended,'BLD');
        BLD_extended.AeroOut = pyroOutPath;
        BLD_extended.encode(self.newBLDfileExtended);

        BLD = LAC.vts.convert(self.newBLDfile,'BLD');
        BLD.AeroOut = pyroOutPath;
        BLD.encode(self.newBLDfile);
    end
else
    answer = questdlg('Would you like to RUN pyro now?','RUN Pyro??','Yes','No','No');
end

if strcmpi(answer,'Yes')
    fprintf('Running Pyro ...\n')
    winopen(batFileName)
    fprintf('Updating .out path in BLD files to %s\n',pyroOutPath);
    BLD_extended = LAC.vts.convert(self.newBLDfileExtended,'BLD');
    BLD_extended.AeroOut = pyroOutPath;
    BLD_extended.encode(self.newBLDfileExtended);

    BLD = LAC.vts.convert(self.newBLDfile,'BLD');
    BLD.AeroOut = pyroOutPath;
    BLD.encode(self.newBLDfile);
else
    fprintf('Run pyro from %s\n',batFileName)
end
    
end


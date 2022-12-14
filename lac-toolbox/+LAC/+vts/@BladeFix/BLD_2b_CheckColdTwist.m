function acceptableTwist = BLD_2b_CheckColdTwist(self)
% BLD_2b_CheckColdTwist() - Checks  VTS hot twist
% against the perfect twist defined in the PyRo .inp file.

% Calculate torsion of blade from simulations at 7.5 m/s
twistResultOutputFolder = fullfile(self.twistSimulationFolder,num2str(self.twistIteration));
if ~isdir(twistResultOutputFolder)
    mkdir(twistResultOutputFolder);
end
torsion = LAC.scripts.bladeTorsion(self.inputs.HotTwistWindSpeed,fullfile(self.twistSimulationFolder,'Loads') ,twistResultOutputFolder);

% Read Pyro input file where wanted hot twist is stated
% Once Pyro Codec is working the below can be used
%pyro = LAC.pyro.convert(Pyro_Input,'INP');
%pyro_radii          = [pyro.SectionTableBlade{1}.data{:,1}]';% Pyro_input.matrix(:,1);
%pyro_OptimalTwist   = [pyro.SectionTableBlade{1}.data{:,3}]';
PyroInput          = self.ConvertPyroInput(self.inputs.AeroInpFile);

pyroRadii          = PyroInput.matrix(:,1);%[pyro.SectionTableBlade{1}.data{:,1}]';% PyroInput.matrix(:,1);
pyroOptimalTwist   = PyroInput.matrix(:,3);%[pyro.SectionTableBlade{1}.data{:,3}]';

bldFile            = LAC.vts.convert(self.newBLDfileExtended,'BLD');

bladeRadii         = bldFile.SectionTable.R;
bladeColdTwist     = bldFile.SectionTable.beta;

torsionRadii       = torsion(:,1);
torsionTorsion     = torsion(:,2);


% calculate new cold twist, cold twist = hot twist - torsion
% interpolate hot twist and torsion to cold twist blade sections
hotTwistInterpolated = interp1(pyroRadii,pyroOptimalTwist,bladeRadii);
torsionInterpolated = interp1(torsionRadii,torsionTorsion,bladeRadii);
% replace NaN with zeros in torsion
torsionInterpolated(isnan(torsionInterpolated)) = 0;
bladeHotTwist = bladeColdTwist+torsionInterpolated;
twistDifference = hotTwistInterpolated-bladeHotTwist;
% New cold twist
if self.inputs.TwistCorrectionFromRadii == 0
    fprintf('Entire blade is twist corrected ...\n')
    bladeColdTwistNew = hotTwistInterpolated-torsionInterpolated;
else
    warning('backtrace','off')
    warning('Blade is only twist corrected from R>=%1.2f m. This is done without smoothening in the transition region and may therefore be subject to unrealistic descrete jumps in torsion.',self.inputs.TwistCorrectionFromRadii)
    warning('backtrace','on')
    bladeColdTwistNew = bladeColdTwist;
    interpolatedSections = bladeRadii>=self.inputs.TwistCorrectionFromRadii;
    bladeColdTwistNew(interpolatedSections) = hotTwistInterpolated(interpolatedSections)-torsionInterpolated(interpolatedSections);
end


figure('Name',sprintf('Cold twist iteration %0.0f',self.twistIteration),'Position',[200 200 1200 600]);
subplot(211);
hold on;
plot(pyroRadii,pyroOptimalTwist,'--r');
plot(bladeRadii,bladeHotTwist,'-r');
plot(bladeRadii,bladeColdTwist,'--b')
plot(bladeRadii,bladeColdTwistNew,'-b')
legend('Target hot twist','Current hot twist','Current cold twist','Next iteration cold twist');
xlabel('Radii [m]');
ylabel('Torsion/twist [deg]')
grid on;
hold off

subplot(212);
hold on;
plot(bladeRadii([1 end]),[-self.inputs.TwistCriterionDeg -self.inputs.TwistCriterionDeg],':k','HandleVisibility','off')
plot(bladeRadii([1 end]),[self.inputs.TwistCriterionDeg self.inputs.TwistCriterionDeg],':k','DisplayName','Maximum allowed difference')
plot(bladeRadii,twistDifference,'DisplayName','Twist difference')
outsideTarget = abs(twistDifference)>self.inputs.TwistCriterionDeg;
plot(bladeRadii(outsideTarget),hotTwistInterpolated(outsideTarget)-(bladeColdTwist(outsideTarget)+torsionInterpolated(outsideTarget)),'or','HandleVisibility','off')
xlabel('Radii [m]');
ylabel('Actual - Optimal [deg]')
legend('show');
currentAxes = get(gca,'YLim');
ylim([min([currentAxes(1) -0.7]) max( [currentAxes(2) 0.7])]);
grid on;

% Change name of the part to have new version of blade.
[filepathBlade, bladeName, extension] = fileparts(self.newBLDfileExtended);
[filepathBladeStandard, bladeNameStandard, extensionStandard] = fileparts(self.newBLDfile);
LAC.savefig(gcf,{'checkColdTwistResults'},twistResultOutputFolder,true);

% Find difference in hot twist aim and what was achieved in VTS
% simulations.
MaxTorsionDiff = max(abs( twistDifference ));
if MaxTorsionDiff > self.inputs.TwistCriterionDeg
    fprintf('Large difference in torsion, suggested to perform additional twist correction, max difference = %0.2f degrees.\n',MaxTorsionDiff);
end

% Catching self.newBLDfile output sensors
bldTemp = LAC.vts.convert(self.newBLDfile,'BLD');
outputSensors = bldTemp.SectionTable.Out;

answer = questdlg(sprintf('Max difference between VTS hot twist and .inp hot twist: %0.2f degrees. Requirement is %0.2f degrees. Is this acceptable?',MaxTorsionDiff,self.inputs.TwistCriterionDeg),'Acceptable twist?','Yes','No','Yes');
switch answer
    case 'No'
        acceptableTwist = false;

        % New cold twist (bldFile.SectionTable.p_ang is misnomered as p_ang, where it is actually Beta_struct, where Beta_struct = Beta + (p_ang - 90))
        p_ang_original = bldFile.SectionTable.p_ang -bldFile.SectionTable.beta+90;
        bldFile.SectionTable.beta = bladeColdTwistNew;
        bladeColdTwistNewPhiOut = bladeColdTwistNew;
        bladeColdTwistNewPhiOutSign = sign(bladeColdTwistNew);
        bladeColdTwistNewPhiOut(abs(bladeColdTwistNew)>self.inputs.PhiOutLimit) = bladeColdTwistNewPhiOutSign(abs(bladeColdTwistNew)>self.inputs.PhiOutLimit).*self.inputs.PhiOutLimit;
        bldFile.SectionTable.PhiOut(2:end) = bladeColdTwistNewPhiOut(2:end); % Output should follow the aerodynamic twist (this is expected by WiC).
        bldFile.SectionTable.p_ang = bldFile.SectionTable.beta+p_ang_original-90; % Update princial axis with new twist angle

        % Add comment that twist correction is performed
        bldFile.comments{end+1} = sprintf('Twist correction performed to better match hot twist, max of previous blade = %0.2f degrees.',MaxTorsionDiff);
        
        % Encode new blades
        self.newBLDfileExtended = fullfile(filepathBlade, sprintf('%s.%03.0f',bladeName, str2double(extension(2:end))+1));
        bldFile.encode(self.newBLDfileExtended);
        
        self.newBLDfile = fullfile(filepathBladeStandard, sprintf('%s.%03.0f',bladeNameStandard, str2double(extensionStandard(2:end))+1));
        bldFile.SectionTable.Out = outputSensors;
        bldFile.encode(self.newBLDfile);
        
        % saving blade iteration results.
        fprintf('Saving %s...\n',fullfile(twistResultOutputFolder,'checkColdTwistResults.txt'));
        fileID = fopen(fullfile(twistResultOutputFolder,'checkColdTwistResults.txt'),'w');
        fprintf(fileID,'%13s\t%15s\t%15s\t%15s\t%15s\t%15s\t%15s\n','Radius [m]  ','Blade cold twist [deg]  ', 'VTS Torsion [deg]  ', 'VTS Hot Twist [deg]  ', 'Aero Twist interp. [deg]   ', 'Delta Twist [deg]  ', 'Corrected Cold Twist [deg]');
        fprintf(fileID,'%10.3f\t\t%13.5f\t\t\t%13.5f\t\t\t%13.5f\t\t\t%13.5f\t\t\t%13.5f\t\t\t%13.5f\r\n',[bladeRadii'; bladeColdTwist'; torsionInterpolated'; bladeHotTwist'; hotTwistInterpolated'; twistDifference'; bladeColdTwistNew']);
        
    case 'Yes'
        self.finalBladeReached = true;
        fprintf('Convergence criteria reached, max difference = %0.2f degrees.\n',MaxTorsionDiff);
        acceptableTwist = true;
        
        % Add comment of twist convergence.
        bldFile.comments{end+1} = sprintf('Max difference between VTS hot twist and .inp hot twist: %0.2f degrees.',MaxTorsionDiff);
        self.newBLDfileExtended = fullfile(self.finalFolder,[bladeName, extension]);
        bldFile.encode(self.newBLDfileExtended);

        self.newBLDfile = fullfile(self.finalFolder,[bladeNameStandard, extensionStandard]);
        bldFile.SectionTable.Out = outputSensors;
        bldFile.encode(self.newBLDfile);
        
        % saving final result.
        fprintf('Saving %s...\n',fullfile(self.finalFolder,'finalTwistResults.txt'));
        fileID = fopen(fullfile(self.finalFolder,'finalTwistResults.txt'),'w');
        fprintf(fileID,'%13s\t%15s\t%15s\t%15s\t%15s\t%15s\n','Radius [m]  ','Blade cold twist [deg]  ', 'VTS Torsion [deg]  ', 'VTS Hot Twist [deg]  ', 'Aero Twist interp. [deg]   ', 'Delta Twist [deg]  ');
        fprintf(fileID,'%10.3f\t\t%13.5f\t\t\t%13.5f\t\t\t%13.5f\t\t\t%13.5f\t\t\t%13.5f\r\n',[bladeRadii'; bladeColdTwist'; torsionInterpolated'; bladeHotTwist'; hotTwistInterpolated'; twistDifference']);
        LAC.savefig(gcf,{'checkColdTwistResults'},self.finalFolder,true);
    otherwise
        error('Program terminated due to missing answer to question.')
end
fprintf(fileID,'\n\n\n');
if ~isempty(outsideTarget)
    fprintf(fileID,'\n\n\n');
    fprintf(fileID,'Sections with delta Twist > %1.2f deg.\n',self.inputs.TwistCriterionDeg);
    fprintf(fileID,'Twist delta is %6.2f deg at radius %6.2f m\n',[hotTwistInterpolated(outsideTarget)-(bladeColdTwist(outsideTarget)+torsionInterpolated(outsideTarget)) bladeRadii(outsideTarget)]');
else
    fprintf(fileID,'%30s\n','OK: All sections have Twist delta within Twist delta criterio');
end
fclose(fileID);

end


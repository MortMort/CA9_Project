currentpath = pwd;
stabilitySetup = fullfile(currentpath,'SetupAll_v002.txt');

orgBldPath     = 'h:\2MW\MK10C\V110\Investigations\44_SingleWeb_StabilityAssessment\PARTS\BLD\Blade_V110_a18_l08_s17_2_WithPA.001 ';
modBldPath     = 'h:\2MW\MK10C\V110\Investigations\44_SingleWeb_StabilityAssessment\PARTS\BLD\Blade_V110_single_web_20150211.004';

orgBld = LAC.vts.convert(orgBldPath,'BLD');
modBld = LAC.vts.convert(modBldPath,'BLD');

figH = orgBld.compareProperties(modBld,'relative');
LAC.savefig(figH,{'CompareProperties'},currentpath,1)
structFields = fields(orgBld.SectionTable);
return

%% Preprocess
for iProp = 1:length(structFields)
    if ismember(iProp,[1,9:13,15:17])
       continue 
    end
    setupfile = LAC.codec.CodecTXT(stabilitySetup);
    tempBld  = orgBld;
    propertyname = structFields{iProp};
    disp(sprintf('Preparing %s',propertyname))
    tempBld.SectionTable.(propertyname)(31:end) = modBld.SectionTable.(propertyname)(31:end);
    newDir = fullfile(currentpath,propertyname);
    mkdir(newDir);
    
    tempBld.encode(fullfile(newDir,'bld.000'))
    figH = orgBld.compareProperties(LAC.vts.convert(fullfile(newDir,'bld.000'),'BLD'),'relative');
    LAC.savefig(figH,{'CompareProperties'},newDir,1)
    
    setupfile.searchAndReplace('h:\2MW\MK10C\V110\Parts\BLD\Blade_V110_a18_l08_s17_2_WithPA.001',fullfile(newDir,'bld.000'))
    setupfile.save(fullfile(newDir,'SetupAll_v002.txt'))
    
end
return
%%
% for iProp = 1:length(structFields)
%     if ismember(iProp,[1,9:13,15:17])
%        continue 
%     end    
%     newDir = fullfile(currentpath,structFields{iProp});
%     Stability.run('level1',fullfile(newDir,'SetupAll_v002.txt'),'calculations')
% end
for iProp = 1:length(structFields)
    if ~ismember(iProp,[4,7,8,14])
       continue 
    end    
    newDir = fullfile(currentpath,structFields{iProp});
    Stability.run('level1',fullfile(newDir,'SetupAll_v002.txt'),'calculations')
end




function VSC_SetupInfo = readVSC_SetupInfo(VSC_SetupInfoPath)
% VSC_SetupInfo = readVSC_SetupInfo(VSC_SetupInfoPath)
% Simple reader for VSC setupInfo file
% VSC_SetupInfoPath - path to the setup info file
% NIWJO 2021

A = textscan(fileread(VSC_SetupInfoPath),'%s','Delimiter','=');
VSC_SetupInfo.BaselinePostload = A{1}{find(strcmp(regexprep(A{1},' ',''),'PostloadsPath'))+1};
VSC_SetupInfo.RootPath = fileparts(VSC_SetupInfoPath);
VSC_SetupInfo.DesignLoads = A{1}{find(strcmp(regexprep(A{1},' ',''),'RNADesignLoads'))+1};
VSC_SetupInfo.PowerFile = A{1}{find(strcmp(regexprep(A{1},' ',''),'PowerFile'))+1};
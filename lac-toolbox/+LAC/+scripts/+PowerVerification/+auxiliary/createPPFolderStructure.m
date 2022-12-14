function createPPFolderStructure()
% createLVFolderStructure, creates the folder structure needed for the load
% verification campaign. It will create folders one level up from the
% folder Mainscript is located in, meaning Mainscript needs to be located
% in a subfolder of the loadverification-investigation folder.


idx_backslash = strfind(pwd,'\');
CurrentFolder = pwd;
CurrentSubFolder = CurrentFolder(idx_backslash(end):end);

mkdir([pwd '\Output']); 
mkdir([pwd '\Output_Figures']);
mkdir([pwd '\Output_Figures_PNG']);
mkdir([pwd '\Reports']);
mkdir([pwd '\Simulations']);
mkdir([pwd '\Measurements']);
mkdir([pwd '\Investigations']);

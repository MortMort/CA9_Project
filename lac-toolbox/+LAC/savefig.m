function savefig(fighandle,filenames,outdir,ow)
% Save matlab figures to emf and fig files.
%
% Syntax:
% savefig(fighandle,filenames)
% savefig(fighandle,filenames,outdir)
% savefig(fighandle,filenames,outdir,ow)
%
% Inputs:
% fighandle = figure handles. 1-by-n array
% filenames = filenames without extension. 1-by-n cell array
% outdir = directory where the files are saved. creates a new directory if non exist. string
%
% Example:
% fighandle(1)=figure; filenames{1}='Myfigure';
% plot(rand(10))
% savefig(fighandle,filenames)
%
% Version History:
% 00: new script by SORSO 14-03-2012
%
% Review:
% 00:
%%
if nargin<3
    outdir=cd;
end
if nargin<4
   ow = 0; % overwrite 
end
outdir=strcat(outdir); % remove blank space
if ~strcmpi(outdir(end),'\') % incert \ if needed
    outdir=strcat(outdir,'\');
end

if isdir(outdir)==1 && ow==0;
    reply = input('Overwrite contents in output folder. Y/N [Y]: ', 's');
    if isempty(reply)
        reply = 'Y';
    end
else
    reply = 'Y';
    if strcmp(reply,'Y') && ~isdir(outdir)
        mkdir(outdir);
    end
end

if strcmpi(reply,'Y') || isempty(reply)
    for i=1:length(filenames)
        saveas(fighandle(i), [outdir,filenames{i}],'png')
%         print(fighandle(i),'-dmeta' , '-r200' ,[outdir,filenames{i}]) % save file to emf file
        hgsave(fighandle(i),[outdir,filenames{i}]); % save file to fig-file
    end
    disp('Figure(s) saved')
else
    disp('No figure saved')
end
end
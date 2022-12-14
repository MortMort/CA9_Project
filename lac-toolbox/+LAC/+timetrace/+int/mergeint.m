function [] = mergeint(indir,outdir)
% Reading loadcase names from INT input folder
inpfile = 'V117LK_20130916_1';
fn=strcat(inpfile,'*.int');
LC = dir([indir fn]);
Ycombine=[];

for j=6:30%length(LC)
    j

    filename=fullfile(indir,LC(j).name)
    [~,~,Ydata] = readint(filename,1,[],[]);    
    [a b]=size(Ydata);    
    Ydata(:,32)=ones(a,1)*j;
    Ycombine=[Ycombine; Ydata(:,1:32)];    
    clear Xdata Ydata    
end

if nargin==1
    outdir=indir;
end
    
intwrite(fullfile(outdir,'wind.int'),1,0.1,Ycombine);
clear all;clc;
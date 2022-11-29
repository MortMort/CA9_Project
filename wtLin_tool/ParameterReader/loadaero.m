%LOADAERO Load Aero-Files containing cp/ct tables
%
%   The program reads a file generated by Aero and
%   extracts the cp, ct tables
%
%   Syntax:  [cP,cT,lambda_tab,theta_tab] = loadaero(filename)
%
%   Input:   filename         name of the input AERO-file
%
%   Outputs: cP(theta,lambda) table of rotor power coefficients
%            cT(theta,lambda) table of thrust coefficients
%            lambda_tab       lambda bins
%            theta_tab        [deg] pitch angle bins
%
%   See also LOADTIP, LOADAERO2
%
%   THK, 05/00
%

function [cP,cT,lambda_tab,theta_tab] = loadaero(filename)


fid = fopen(filename,'r');

if fid == -1
   error('input file not found')
end

%find cp table

string = ' ';
while ~strcmp(string,'theta_min')
   [string,status] = fscanf(fid,'%s',1);
   if status == 0
       fclose(fid);
       error('no cP table found')
   end
end

fseek(fid,-45,'cof');
fgets(fid);
fgets(fid);
theta_min = fscanf(fid,'%f',1);
theta_max = fscanf(fid,'%f',1);
theta_step = fscanf(fid,'%f',1);
fgets(fid);
lambda_min = fscanf(fid,'%f',1);
lambda_max = fscanf(fid,'%f',1);
lambda_step = fscanf(fid,'%f',1);
fgets(fid);
fgets(fid);
fgets(fid);
fgets(fid);

lambda_tab = [lambda_min:lambda_step:lambda_max]';
theta_tab = [theta_min:theta_step:theta_max]';

[cpmat,COUNT] = fscanf(fid,'%f',[length(theta_tab)+1,length(lambda_tab)]);
cP = cpmat(2:length(theta_tab)+1,:);
fgets(fid);
fgets(fid);
string = fscanf(fid,'%s',1);
fgets(fid);
if (~strcmp(string,'CT-table') && ~strcmp(string,'CT-tabel'))
    cT = [];
    warning('no cT table found')
    fclose(fid);
    return
end
fgets(fid);
[ctmat,COUNT] = fscanf(fid,'%f',[length(theta_tab)+1,length(lambda_tab)]);
cT = ctmat(2:length(theta_tab)+1,:);

fclose(fid);



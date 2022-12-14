function C = sensread(fn)
%   Reading the sensor file
%
%   [C] = sensread(fn)
%
%   Input:  fn:  The sensor file
%   Output: Sensorno. Forst Offset korr. c  volt unit  name  discription
%
%   Example:
%   [C] = sensread('C:\VestasToolbox\TLtoolbox\Example_Inputs\LoadCases_reduced\INT\sensor')
%
%   05-10-2011: ALKJA Update - Description line also included into C.

if exist(fn) == 0
    sprintf('%s','Error:  Cannot find sensor file"');
    return
end

fid=fopen(fn);
for i=1:2
    x=fgetl(fid);   %reading the header 
end
    % C = textscan(fid,'%f %f %f %f %f %s %s %*[^\n]');
    C = textscan(fid,'%f %f %f %f %f %s %s %[^\n]');

fclose(fid);

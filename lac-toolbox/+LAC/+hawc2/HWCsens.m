function [sensforHAWC2]=HWCsens(sentxtfile)
%% reading the required HAWC sensor from input sensor text file
fileID=fopen(sentxtfile);
sensforHAWC2=textscan(fileID,'%s %s');
fclose(fileID);
end
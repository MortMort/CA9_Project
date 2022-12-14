function [] = bladesweep(inputfile)
% Open and read blade file
Bld = LAC.vts.convert(inputfile,'BLD');

if Bld==-1
    error('%s not read.',inputfile)
end
    
[pathToInputfile,filename, ext] = fileparts(inputfile);

% Calculate sweep
rotorRadius = Bld.SectionTable.R;
bladeRadius = rotorRadius-rotorRadius(1);
sweep       = Bld.SectionTable.UE0;

coeffs   = [bladeRadius.^3 bladeRadius]\sweep;    %non-square matrix: least-squares solution
sweepFit = [bladeRadius.^3 bladeRadius]*coeffs; %fit

coefficientA = coeffs(2);
coefficientB = coeffs(1);

% Plot correction
plot(bladeRadius,sweep,'b',bladeRadius,sweepFit,'r');
legend('origprebend','calcprebend','location','best' );

% Write file with correction
fid=fopen(fullfile(pathToInputfile,'prebendoutput.txt'),'w');
fprintf(fid,'\n PLEASE NOTE THE CURVE FITTING IS ONLY FOR CURVES WITH EQUATION GIVEN BELOW');
fprintf(fid,'\n The curve equation is : Y = AX + B*X^3');
fprintf(fid,'\n Coefficient A : %f', coefficientA);
fprintf(fid,'\n Coefficient B : %f', coefficientB);
fprintf(fid,'\n Gammarootvalue : %f', coefficientA*180/pi);

fprintf(fid,'\n\n Bladefile prebend input');
fprintf(fid,'\n');
fprintf(fid,'\n radius   bldprebendinput');   
for i = 1:length(bladeRadius);
    fprintf(fid,'\n %10.5f  %11.6f ', rotorRadius(i), coefficientB*bladeRadius(i)^3);
end
fclose(fid);


if abs(coefficientA*180/pi)>=0.05
    Bld.SectionTable.UE0 = coefficientB*bladeRadius.^3;
    Bld.GammaRootEdge    = coefficientA*180/pi;
else
    Bld.GammaRootEdge=0;
end

% Write blade file
Bld.encode(fullfile(pathToInputfile,[filename '_sweepcorrection' ext]))
end



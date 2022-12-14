
function CreateBatFiles(Dat_Path,idx,data)
cd([pwd '\Output'])


fid=fopen('Step00_Data.txt','wt');
fid_copyINT=fopen('CopyINT.bat','wt');
fid_copySTA=fopen('CopySTA.bat','wt');
fid_mkSTA=fopen('MkSTA.bat','wt');
%fprintf(fid,'%s\t %22s %12s %12s %12s %12s %12s %12s %12s %12s %12s\n','Name','vind','turb','vdir','rpm','pit','Pres','temp','seed','shear','rho');
fprintf(fid,'%s\t %22s %12s %12s %12s\n','Name','vind','turb','rpm','pit');

INT_dir=strrep(Dat_Path,'\dat','\int');
STA_dir=strrep(Dat_Path,'\dat','\sta');
for i=1:length(data.dat1.filedescription)
        %fprintf(fid,'%20s\t %6.2f %12.4f %12.2f %12.2f %12.2f %12.0f %12.2f %12s %12.2f %12.3f\n',data.dat1.filename{i,1},data.dat1.mean(i,wsp_sens(1)),data.dat1.mean(i,turb_sens(1)),-data.dat1.mean(i,yawerror_sens(1)),data.dat1.mean(i,rpm_sens(1)),data.dat1.mean(i,pitch_sens(1)),data.dat1.mean(i,pres_sens(1)),data.dat1.mean(i,temp_sens(1)),seed{i},wsh_avg(i,1),data.dat1.mean(i,rho_sens(1)));
        fprintf(fid,'%20s\t %6.2f %12.4f %12.2f %12.2f\n'...
        ,data.dat1.filename{i,1},data.dat1.mean(i,idx.WSP)...
        ,data.dat1.mean(i,idx.turb),data.dat1.mean(i,idx.rpm)...
        ,data.dat1.mean(i,idx.PitchC));
        fprintf(fid_copyINT,strcat('%4s\t %',num2str(length(INT_dir)+length(data.dat1.filename{i,1})+4),'s\t %25s\n'),'copy', strcat('"',INT_dir,data.dat1.filename{i,1},'.int','"'),strcat('"',data.dat1.filename{i,1},'.int','"'));
        fprintf(fid_copySTA,strcat('%4s\t %',num2str(length(STA_dir)+length(data.dat1.filename{i,1})+4),'s\t %25s\n'),'copy', strcat('"',STA_dir,data.dat1.filename{i,1},'.sta','"'),strcat(data.dat1.filename{i,1},'.sta'));
        fprintf(fid_mkSTA,strcat('%10s\t %',num2str(length(data.dat1.filename{i,1})+4),'s\t %25s\n'),'statist2', strcat(data.dat1.filename{i,1},'.int'),strcat(data.dat1.filename{i,1},'.sta'));
end

fclose(fid);
fclose(fid_copyINT);
fclose(fid_copySTA);
fclose(fid_mkSTA);

cd([pwd '\..\']);
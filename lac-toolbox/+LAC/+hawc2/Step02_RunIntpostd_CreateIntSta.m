%% Creating INT,STA and Postprocessing the results
% Required inputs in the Dialogue box
% -VTS Text file
% -Run Locally or in the cluster -1/0(Cluster)
% -Interested in Parameter or Reference Study - 1/0(Reference)
% -CreateINT -1/0
% -CreateSTA -1/0
% -DeleteINT -1/0
% -RunIntpostD -1/0
% Author - KAVAS - 11th of April 2018.

clear all; close all;
rootfol=[pwd '\'];

%% initializing
supportfile='h:\FEATURE\1PCriticalOperation\Scripts\+HAWC\_Support\';

prompt={'VTS Txt file','RunLocally 1/0(Cluster)','Parameter/Reference Study 1/0(Reference)','CreateINT','CreateSTA','DeleteINT','RunIntPostD','HAWC12.2 Sensor file'};title='User Inputs'; 
definput={'V120_2.00_IECS_HH92_INF_STE_60HZ_1P_0061_4920_858876_bc3bb1.txt','0','1','1','1','0','0','h:\FEATURE\1PCriticalOperation\Scripts\+HAWC\_Support\sensor'};
userinput=inputdlg(prompt,title,[1 70],definput);

%user inputs
txtfile=userinput{1};
runlocally=str2double(userinput{2});% 1 local/0 for cluster
runSweep=str2double(userinput{3});
int=str2double(userinput{4});
sta=str2double(userinput{5});
delint=str2double(userinput{6});
intpostd=str2double(userinput{7});
sensorfile=userinput{8};

%% Folder Setup
if runSweep
    invfol=dir([rootfol,'01_*']);
else
    clear invfol
    invfol.name='Ref';
end
%% Creating INT and STA files Locally/Cluster
    if runlocally==1
        if int==1
            %HAWC2UpdateINTAndSensorFile
            for i=1:length(invfol)
                disp(['Creating int files for:',invfol(i).name]);
                copyfile(sensorfile,fullfile(rootfol,invfol(i).name,'RES'));       

                %running HAWC2UpdateINTAndSensorFile
                sysCommandLine = ['start ', fullfile(rootfol,invfol(i).name,'INPUTS','HAWC2UpdateINTAndSensorFiles.bat')];
                cd([rootfol,invfol(i).name,'\INPUTS']);
                [staStatus staResults] = system(sysCommandLine);
            end
        end
        
        if sta==1
            for i=1:length(invfol)
                disp(['Creating sta files for:',invfol(i).name]);
                cd([rootfol,invfol(i).name,'\INPUTS']);
                copyfile(fullfile(rootfol,invfol(i).name,'INPUTS\RUNHAWC2.bat'),fullfile(rootfol,invfol(i).name,'INPUTS\CreateSTA.bat')); 
                stafn = fullfile(rootfol,invfol(i).name,'INPUTS','CreateSTA.bat');  
                staedit    = LAC.codec.CodecTXT(stafn);

                staedit.searchAndReplace('flxctrl','createINTandSTA');
                staedit.save(stafn); 
                copyfile(fullfile(supportfile,'createINTandSTA.bat'),fullfile(rootfol,invfol(i).name,'INPUTS'));
                copyfile(fullfile(supportfile,'createINTandSTA.bat'),fullfile(rootfol,invfol(i).name,'RES'));

                %running Createstafile.bat
                sysCommandLine = ['start ', fullfile(rootfol,invfol(i).name,'INPUTS','CreateSTA.bat')];
                [staStatus staResults] = system(sysCommandLine);        

            end
        end

        %deleting files
        if delint==1
            for i=1:length(invfol)
                disp(['Deleting the files:',invfol(i).name]);
                delete(fullfile(rootfol,invfol(i).name,'INT\sen*'));
                copyfile(fullfile(supportfile,'sensor'),fullfile(rootfol,invfol(i).name,'RES'))
            end
        end
        
    elseif runlocally ==0
        if int==1 || sta==1
        % runing in the cluster
         for i=1:length(invfol)
                disp(['Creating int files in cluster for:',invfol(i).name]);
                copyfile(sensorfile,fullfile(rootfol,invfol(i).name,'RES'));
                copyfile(fullfile(supportfile,'createINTandSTA.bat'),fullfile(rootfol,invfol(i).name,'RES')); 
                copyfile(fullfile(supportfile,'createINTandSTA.bat'),fullfile(rootfol,invfol(i).name,'INPUTS'));            
                movefile(fullfile(rootfol,invfol(i).name,'INPUTS','HAWC2rundoit.bat'),fullfile(rootfol,invfol(i).name,'INPUTS','HAWC2rundoit_org.bat'));
                copyfile(fullfile(supportfile,'HAWC2rundoit.bat'),fullfile(rootfol,invfol(i).name,'INPUTS')); 
                sysCommandLine=(['DCClient -server dkaarwhpc02 addvtsbatch ',fullfile(rootfol,invfol(i).name,'INPUTS','RUNHAWC2.bat'), ' -timeout 1000 -priority 5 -tag VTSview -maxruns 10']);
                disp(sysCommandLine);
                system(sysCommandLine);             
            end
        end
    end
    
%% Running IntPostD         
      if intpostd==1    
        for i=1:length(invfol)
        %copy frq and mas file
        copyfile(fullfile(rootfol,'_VTS\Loads\INPUTS\',strrep(txtfile,'.txt','.frq')),fullfile(rootfol,invfol(i).name,'INPUTS'));
        copyfile(fullfile(rootfol,'_VTS\Loads\INPUTS\',strrep(txtfile,'.txt','.mas')),fullfile(rootfol,invfol(i).name,'INPUTS'));        
        
        % modify the pl file
        LAC.HAWC2.ModifyPlfile(rootfol,invfol(i).name);
              
        %run intpostd
        cd([rootfol,invfol(i).name])
        sysCommandLine = ['intpostd ' strrep(txtfile,'.txt','.frq')];   
        system(sysCommandLine);  
        end
      end 
% Reading Out files from blades to picturize and identify the files to be
% disregarded while generating the lookup table.
% V01 : 1st of July 2020
% Author: KAVAS
% Inputs 
    % Pyro path for all the outfiles
    % folder to disregard
% Output
    % plots showing the comparing of AEP and Cp
clear;close all;clc

%% Inputs
prompt={'Icing Output Files','Folders to disregard'};label='Step01:Icing Output Inputs'; 
definput={'h:\FEATURE\ColdClimate\Simulation_Models\Pyro_IceShapes\V150_24062020\PyRO\','BARE-CFX'};
userinput=inputdlg(prompt,label,[1 100],definput);

inpath=userinput{1};

Opath=dir(inpath);Opath(ismember( {Opath.name}, {'.', '..'})) = [];Opath = Opath([Opath.isdir]);
if ~isempty(userinput{2})
    ftodisreg=userinput{2};
    Opath(find(strcmp({Opath.name},ftodisreg)))=[];
end

%% Reading the Out files

for i=1:length(Opath)
    OFiles=dir([fullfile(Opath(i).folder,Opath(i).name),'\*.OUT']);
    tempfiles=dir([fullfile(Opath(i).folder,Opath(i).name),'\*.out']);
    
    % remove non output in baseline
    if i==1 & length(tempfiles)>1        
        tempfiles(find(~contains({tempfiles.name},'mixed')))=[];
    end
    
    % reading outfiles
    for ii=1:length(tempfiles)
        disp(['Reading: ',tempfiles(ii).name]);
%         fn=regexprep((tempfiles(ii).name(end-12:end-8)),{'_','-','\.'},{'','',''}); 
        fn=regexprep((tempfiles(ii).name(1:end-4)),{'_','-','\.'},{'','',''}); 
        raw.(regexprep(Opath(i).name,{'_','-'},{'',''})).(fn)=LAC.pyro.ReadPyroOutFile(fullfile(tempfiles(ii).folder,tempfiles(ii).name));
    end  
end

%% pitcurise the data
% 3D plots of the Cp
icn=fieldnames(raw);
BetzLimit            = 16/27;
for i =1:length(icn)
    isn=fieldnames(raw.(icn{i})); % identify the ice shapes
    for j=1:length(isn)
        figure
        mesh(raw.(icn{i}).(isn{j}).Col_2_Theta,raw.(icn{i}).(isn{j}).Row_2_Lambda,raw.(icn{i}).(isn{j}).Cp_table_2)
        xlabel('Pitch angle [deg]'); ylabel('\lambda [-]'); zlabel('Cp [-]'); 
        zlim([0 BetzLimit]); caxis([0,BetzLimit]);
        title(['CP-table calculated for ',num2str(icn{i}),' : ',num2str(isn{j})]);
    end
end

% ploting the AEP
AEP=[];folTag=[];n=1;
for i =1:length(icn)
    isn=fieldnames(raw.(icn{i})); % identify the ice shapes
    %extracting data for AEP
    for j=1:length(isn)
        AEP=[AEP raw.(icn{i}).(isn{j}).AEP];
        folTag{n}=[icn{i} ':',isn{j}];
        n=n+1;
    end
    
    %Ploting AEP
    if i==length(icn)
        figure
        subplot(1,2,1)
        bar(AEP);
        set(gca,'xticklabel',folTag,'DefaultAxesTickLabelInterpreter', 'none');
        xtickangle(45);
        title('Comparison of absolute AEP');  
        subplot(1,2,2)
        plot(AEP./AEP(1),'-*','LineWidth',1.5);
        text([1:length(AEP)],[AEP./AEP(1)],num2cell(AEP./AEP(1)))
        set(gca,'xticklabel',folTag,'DefaultAxesTickLabelInterpreter', 'none');
        xtickangle(45);        
        title('Comparison of AEP to Baseline');        
    end
end

%ploting the all the Cp for given TSR
prompt={'Lambda of Interest','Plot Subplot'};label='Step02:Input the interested lambda'; 
definput={'9.2','0'};
userinput=inputdlg(prompt,label,[1 40],definput);
inlambda=str2double(userinput{1});plotsub=str2double(userinput{2});
for i =1:length(icn)
    if plotsub || i==1
        figure
    end
    isn=fieldnames(raw.(icn{i})); % identify the ice shapes
    for j=1:length(isn)
        idxlamb=find(raw.(icn{i}).(isn{j}).Row_2_Lambda==inlambda);
        plot(raw.(icn{i}).(isn{j}).Col_2_Theta,raw.(icn{i}).(isn{j}).Cp_table_2(idxlamb,:),'LineWidth',1.5);
        hold on;
    end
    
xlabel('Pitch angle [deg]');ylabel('Cp [-]');
title(['Comparison of Cp stacking for lambda:', num2str(inlambda)]);
grid on;
ylim([0 BetzLimit]); 
    if plotsub
        legend(isn)
    end
end
if plotsub==0
    legend(folTag);
end

%ploting the induction
figure
isn=fieldnames(raw.(icn{1}));
plot(raw.(icn{1}).(isn{1}).Row_1_Radius,raw.(icn{1}).(isn{1}).a1_1);
xlabel('Blade radius [m]');ylabel('Induction a [-]');
grid on;
legend(num2str(raw.(icn{1}).(isn{1}).Col_1_Wsp))



function DLC13(raw,fidout,FLCGS)

% to write the DLC 1.3 as in
%% 
    if nargin==2
        disp('5. Writing DLC13 as in');
        idx=find(contains(raw.LoadCaseNames,'13') & contains(raw.LoadCaseNames,'etm'));        
        fprintf(fidout,'**** DLC 1.3  \n\n');

        for k=1:length(idx)
            for j=1:length(raw.LoadCases{idx(k)})
                fprintf(fidout,raw.LoadCases{idx(k)}{j});  
                if j==length(raw.LoadCases{idx(k)})
                    fprintf(fidout,[' rho 1.325 ']);  
                    if str2num(raw.LoadCaseNames{idx(k)}(3:4))>=floor(raw.WindSpeeds('Vrat')-1)
                    	fprintf(fidout,[' Vhub ' num2str(floor(raw.WindSpeeds('Vrat'))-2) ' -2000 -1800 Vhub ' num2str(raw.LoadCaseNames{idx(k)}(3:4)) ' -1300 -1000']);    
                    end
                end                
                fprintf(fidout,[ '\n']);
            end
            fprintf(fidout,[ '\n']);          
        end
    elseif nargin>2
        disp('6. Writing DLC13 with FLC gain scheduling ');
        wsp_vrat=floor(raw.WindSpeeds('Vrat')/2)*2;
        idx=find(contains(raw.LoadCaseNames,['13',num2str(wsp_vrat,'%02d'),'etm']));
        
        prompt={'Default FLC GS: Px_FLC_NomPit2TrqSens','Percentage reduction'};title='DLC13: FLC GS'; 
        definput={'-28000000','30'};
        userinput1=inputdlg(prompt,title,[2 50],definput);
        FLC_GS=userinput1(1); per_reduction=userinput1(2);
        
        fprintf(fidout,['**** DLC 1.3 FLC gain scheduling increaased by ', num2str(str2double(per_reduction)) 'Per. from ', num2str(str2double(FLC_GS)) ,' Px_FLC_Pit2TrqSensRateLim not disturbed']);
        fprintf(fidout,[ '\n\n']);
        
        for k=1:length(idx)
            for j=1:length(raw.LoadCases{idx(k)})
                if j==1
                    fprintf(fidout,strrep(raw.LoadCases{idx(k)}{j},'etm','etmFLCGS')); 
                elseif j==2
                    fprintf(fidout,raw.LoadCases{idx(k)}{j});
                elseif j==length(raw.LoadCases{idx(k)})
                    fprintf(fidout,[raw.LoadCases{idx(k)}{j},' rho 1.325']);
                    fprintf(fidout,[' Vhub ' num2str(floor(raw.WindSpeeds('Vrat'))-2) ' -2000 -1800 Vhub ' num2str(raw.LoadCaseNames{idx(k)}(3:4)) ' -1300 -1000']);    
                    fprintf(fidout,[' OverrideCSVParameter ProdCtrl Px_FLC_NomPit2TrqSens ' num2str(str2double(FLC_GS)*(1+str2double(per_reduction)/100)) ' 9999 ' ]);                    
                end
                fprintf(fidout,[ '\n']);
            end
            fprintf(fidout,[ '\n']);          
        end        

    end
end
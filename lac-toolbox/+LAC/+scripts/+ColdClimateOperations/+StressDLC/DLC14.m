function DLC14(raw,fidout)

% to write the deterministic DLC 1.4 as in
%% 
        disp('6. Writing DLC14 deterministic as in');
        idx=find(contains(raw.LoadCaseNames,'14Ecdvraa') & contains(raw.LoadCaseNames,'NT'));
        fprintf(fidout,'**** DLC 1.4  \n\n');
        
        fprintf(fidout,'beginfamily - \n\n');

        for k=1:length(idx)
            for j=1:length(raw.LoadCases{idx(k)})
                fprintf(fidout,raw.LoadCases{idx(k)}{j});  
                if j==length(raw.LoadCases{idx(k)})
                    fprintf(fidout,[' rho 1.325']);   
                    fprintf(fidout,[' Vhub ' num2str(floor(raw.WindSpeeds('Vrat'))-2) ' -2000 -1800 Vhub Vrat -1300 -1000']);    
                end                
                fprintf(fidout,[ '\n']);
            end
            fprintf(fidout,[ '\n']);          
        end
        
        fprintf(fidout,'endfamily \n\n');
end
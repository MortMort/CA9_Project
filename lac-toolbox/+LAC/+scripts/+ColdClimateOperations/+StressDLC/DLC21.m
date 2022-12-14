function DLC21(raw,fidout,LC)

% To write DLC2.1RPY and DLC2.1PSBB as in
%%

switch LC
    case 'RPY'
        disp('7. Writing DLC21RPY as in');
        idx=find(contains(raw.LoadCaseNames,'21RPYv') | contains(raw.LoadCaseNames,'21RPYV'));
        fprintf(fidout,'**** DLC 2.1 RPY  \n\n');      
        
    case 'PSBB'
        disp('8. Writing DLC21PSBB as in');
        idx=find(contains(raw.LoadCaseNames,'21PSBBv') | contains(raw.LoadCaseNames,'21PSBBV'));
        fprintf(fidout,'**** DLC 2.1 PSBB  \n\n');            
end

        for k=1:length(idx)
            for j=1:length(raw.LoadCases{idx(k)})
                fprintf(fidout,raw.LoadCases{idx(k)}{j});  
                if j==length(raw.LoadCases{idx(k)})
                    fprintf(fidout,[' rho 1.325 ']);   
                    if floor(raw.WindSpeeds(raw.LoadCases{idx(k)}{j}(7:10)))>=floor(raw.WindSpeeds('Vrat'))
                        fprintf(fidout,[' Vhub ' num2str(floor(raw.WindSpeeds('Vrat'))-2) ' -2000 -1800 Vhub ' num2str(floor(raw.WindSpeeds(raw.LoadCases{idx(k)}{j}(7:10)))) ' -1300 -1000']);  
                    end
                end                
                fprintf(fidout,[ '\n']);
            end
            fprintf(fidout,[ '\n']);          
        end  
end
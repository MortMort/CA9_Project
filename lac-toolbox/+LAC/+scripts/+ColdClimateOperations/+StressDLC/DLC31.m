function DLC31(raw,fidout,LC)

% To write DLC3.1NTM and add DLC3.1ETM
%%

disp(['10. Writing DLC31 ',LC]);
idx=find(contains(raw.LoadCaseNames,'31PRV'));

if length(idx)<3
    wsp_vrat=floor(raw.WindSpeeds('Vrat')/2)*2;
    idx=[idx find(contains(raw.LoadCaseNames,['31PR',num2str(wsp_vrat)]))];
end

fprintf(fidout,['**** DLC 3.1 ', LC  ,'\n\n']);

for k=1:length(idx)
    for j=1:length(raw.LoadCases{idx(k)})
        if j==1
        fprintf(fidout,strrep(raw.LoadCases{idx(k)}{j},'31PR',['31PR',LC]));  
        end
        fprintf(fidout,raw.LoadCases{idx(k)}{j});  
        if j==length(raw.LoadCases{idx(k)})
            fprintf(fidout,[' rho 1.325 ']);                    
        end                
        fprintf(fidout,[ '\n']);
    end
    fprintf(fidout,[ '\n']);          
end  
end
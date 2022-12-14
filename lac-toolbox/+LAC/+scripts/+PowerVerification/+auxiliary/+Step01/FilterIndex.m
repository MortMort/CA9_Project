function [IndexFinal] = FilterIndex(data,filters)
%% Application of filters - application of DQC filters
FiltersTablesDQC=getfield(filters,'DQC_filter_table');

% FiltersTables=filters.([DataType '_filter_table']);
% clear filters

% Filter index
IndexState=strcmp(FiltersTablesDQC.state,'ON');
IndexKeep=strcmp(FiltersTablesDQC.mode,'keep');
IndexDiscard=strcmp(FiltersTablesDQC.mode,'discard');
IndexKeep = IndexState==1 & IndexKeep==1;
IndexDiscard = IndexState==1 & IndexDiscard==1;

% Generating filter index
IndexFinalDQC=logical(ones(size(data.timenum)));
for j=1:size(FiltersTablesDQC.state,1)
    if IndexDiscard(j)==1;
        IndexFilter=eval(FiltersTablesDQC.filter{j});
        IndexFilter=IndexFilter==0;
    elseif IndexKeep(j)==1;
        IndexFilter=eval(FiltersTablesDQC.filter{j});
    end
    % Combining filter index
    IndexFinalDQC = IndexFinalDQC==1 & IndexFilter;
end

IndexFinal=IndexFinalDQC;

%% Application of filters - application of Run filters
% Looking for the run filters
try getfield(filters,'Run_filter_table');
    RunExist=1;
    FiltersTablesRun=getfield(filters,'Run_filter_table');
catch
    try getfield(filters,'RUN_filter_table');
        RunExist=1;
        FiltersTablesRun=getfield(filters,'RUN_filter_table');
    catch
        RunExist=0;
    end
end

% Generating filter index if Run filters exist
if RunExist==1;
    % Filter index
    IndexState=strcmp(FiltersTablesRun.state,'ON');
    IndexKeep=strcmp(FiltersTablesRun.mode,'keep');
    IndexDiscard=strcmp(FiltersTablesRun.mode,'discard');
    IndexKeep = IndexState==1 & IndexKeep==1;
    IndexDiscard = IndexState==1 & IndexDiscard==1;
    
    % Generating filter index
    IndexFinalRun=logical(ones(size(data.timenum)));
    for j=1:size(FiltersTablesRun.state,1)
        if IndexDiscard(j)==1;
            IndexFilter=eval(FiltersTablesRun.filter{j});
            IndexFilter=IndexFilter==0;
        elseif IndexKeep(j)==1;
            IndexFilter=eval(FiltersTablesRun.filter{j});
        end
        % Combining filter index
        IndexFinalRun = IndexFinalRun==1 & IndexFilter;
    end   
    IndexFinal=IndexFinalDQC==1 & IndexFinalRun==1;
end

end 

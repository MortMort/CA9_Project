function LS = fBlade_CheckStall(LS, Outputs, Setup)
import LAC.scripts.TimeInStall.*
%% First loop goes through all the folders, reads the sensors and check stall AoA
LS = fGetStallAoA(LS,Setup,Outputs);


%% Plots based on STA files (min, mean and max AoA, at a given radius position, at a given wind speed)
if ~isempty(Outputs.MinMeanMaxAoA)
%     for i_LS = 1:length(LS)
%         [LS{i_LS}] = fMinMeanMaxAoA(LS{i_LS},Outputs,Setup);
        [LS] = fMinMeanMaxAoA(LS,Outputs,Setup);
%     end
end

[LS] = fTimeInStall(LS,Outputs,Setup);

end

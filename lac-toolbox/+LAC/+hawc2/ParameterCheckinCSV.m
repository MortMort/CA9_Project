function [HWC]=ParameterCheckinCSV1(rootfol,VTS,HWC)
%% This function Identifies the CSV file for controller update.
fn=fieldnames(VTS);

    for i=1:length(HWC.Parameter)
        if contains(HWC.Parameter{i},'TWR')
            HWC.Parameter{i,2}='Master';
        else        
        %existance of parameters            
            for ii=1:length(fn)
                temp_ctlfile=LAC.codec.CodecTXT(fullfile(rootfol,'_VTS\Loads\INPUTS\',VTS.(fn{ii})));
                [temp_ctlfile_txt temp_ctlfile_line] = temp_ctlfile.search(HWC.Parameter{i,1});
                if isempty(temp_ctlfile_txt)
                    % do nothing
                else
                    HWC.Parameter{i,2}=VTS.(fn{ii});
                end
            end
        end
    end
end
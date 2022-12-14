function ModifyEogSgust(base_prep, mode0_pc_file, pc_file, sgust_dlcs)
% Function to modify EOG DLCs that are defined in terms of 'sgust' for noise modes
%
% It changes the 'sgust' values in these DLCs in accordance to the SO modes power cuve
% The new 'sgust' value is calculated based on the ratio between the noise mode and mode 0 power curves
% More info can be found in the Noise Modes Guideline (0073-8946.V03)
% 
% SYNTAX:
% 	LAC.scripts.NoiseModes.ModifyEogSgust(base_prep, mode0_pc_file, pc_file, sgust_dlcs)
%
% INPUTS:
% 	base_prep - Full path to baseline prep file to modify
% 	mode0_pc_file - Full path to Mode 0 power curve ('..\PC\Normal\Rho1.225\pc_(...).txt')
% 	pc_file - Full path to SO mode power curve ('..\PC\Normal\Rho1.225\pc_(...).txt')
% 	sgust_dlcs - Cell with DLCs to modify (ex: {'32PREog', '33PREdc'}), case sensitive
%
% OUTPUTS:
% 	Modified prep file ('_modified.txt'), placed in same folder as the input prep file
%
% VERSIONS:
% 	2021/09/04 - AAMES: V00

%% Read pc files and get WS and power
pc_nrs_data = LAC.pc.ReadPCFile(pc_file);
ws_nrs = pc_nrs_data.Power.Wind;
pow_nrs = pc_nrs_data.Power.Power;
pc_mode0_data = LAC.pc.ReadPCFile(mode0_pc_file);
ws_mode0 = pc_mode0_data.Power.Wind;
pow_mode0 = pc_mode0_data.Power.Power;

%% Get wind speeds from prep file
prep_gen_data = LAC.vts.convert(base_prep, 'REFMODEL');
wspeeds_str = prep_gen_data.WindSpeeds.keys;
wspeeds_val = cell2mat(prep_gen_data.WindSpeeds.values);

%% Read DLCs in prep, get WS and sgust and do the ratio based on the PC values
fid = fopen(base_prep,'r');
prep_data = textscan(fid,'%s','Delimiter','\n');
prep_data = prep_data{1,1};
fclose(fid);

for lc = 1:length(sgust_dlcs)
    ind_dlc = find(~cellfun(@isempty,strfind(prep_data,sgust_dlcs{lc})));
    for id = 1:length(ind_dlc)
        line_ws = prep_data{ind_dlc(id)+2};
        line_elems = strsplit(line_ws);
        ws_str = line_elems{3};
        ws_val = wspeeds_val(~cellfun(@isempty,strfind(wspeeds_str,ws_str)));
        ratio = get_pc_pow_ratio(ws_val,ws_nrs,ws_mode0,pow_nrs,pow_mode0);
        if ratio ~= 1 % change only if ratio <> 1
            sgust_ind = find(~cellfun(@isempty,strfind(line_elems,'sgust')));
            sgust_val = str2double(line_elems{sgust_ind+2});
            new_sgust_val = ratio*sgust_val;
            old_expr = sprintf('%s %s %s',line_elems{sgust_ind:sgust_ind+2});
            new_expr = sprintf('%s %s %.2g',line_elems{sgust_ind:sgust_ind+1},new_sgust_val);
            prep_data{ind_dlc(id)+2} = regexprep(prep_data{ind_dlc(id)+2},old_expr,new_expr);
        end
    end
end

%% Copy and modify prep file
new_prep = strrep(base_prep,'.txt','_modified.txt');
copyfile(base_prep,new_prep);
fid = fopen(new_prep,'w+');
fprintf(fid,'%s\n',prep_data{:});
fclose(fid);
end

%% Aux functions
function ratio = get_pc_pow_ratio(ws_val,ws_nrs,ws_mode0,pow_nrs,pow_mode0)
p_mode0 = interp1(ws_mode0,pow_mode0,ws_val);
p_nrs = interp1(ws_nrs,pow_nrs,ws_val);
ratio = p_nrs/p_mode0;
end
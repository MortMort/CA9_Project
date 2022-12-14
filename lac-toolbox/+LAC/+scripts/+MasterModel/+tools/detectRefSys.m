function refsys = detectRefSys(path_info)
% Function that detect the turbine reference system, specifically
% the MB/MS sensors.

try any(path_info.Availability == true);
    idx = find(path_info.Availability,1,'first');
    path = path_info.Paths{idx};
catch
    warning('No MainLoad.txt available in pathlist. Reconsider.');
    path = path_info.Paths{1};
end

parts = strsplit(path, filesep);
sen_path = fullfile(strjoin(parts(1:end-2),filesep),filesep,'INT',filesep,'sensor');

sen = LAC.vts.convert(sen_path,'SENSOR');

ispresent = cellfun(@(s) regexp(s,'(?<=^M.)MB|MS(?=.)','match'), sen.name, 'UniformOutput', false);
idx = find(cellfun(@(s) ~isempty(s),ispresent));

try any(idx);
    refsys = char(ispresent{idx(1)});
catch
    warning('Could not detect reference system. Reconsider.');
    refsys = '';
end
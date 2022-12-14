classdef TurbulenceFiles < handle
    methods
        function output = get(~, folder)
            output = struct();
            
            % Remove trailing slash
            [a, b, c] = fileparts(folder);
            folder = [a, b, c];
            
            % Find files
            obj = lib.SearchFiles();
            obj.add([folder '\**\*.*']);
            output.files = obj.getFoundFiles();
            output.md5hash = {};
            
            % Calculate MD5Hash
            options.Input  = 'file';
            options.Method = 'MD5';
            options.Format = 'hex';
            for i = 1: length(output.files)
                output.md5hash{end+1} = lib.DataHash(output.files{i}, options);
            end
        end
    end
end

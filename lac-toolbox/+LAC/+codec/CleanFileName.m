classdef CleanFileName < handle
    methods
        function output = clean(self, name, filename, partsfolder)
            output = self.absolutePath(filename, partsfolder);
            switch(name)
                case 'parts'
                    cleanfilename = self.getCleanPartFilename(output);
                case 'profiles'
                    cleanfilename = self.getCleanProfileFilename(output);
                case 'parameters'
                    cleanfilename = self.getCleanParameterFilename(output);
                otherwise
                    cleanfilename = '';
            end
            
            if ~isempty(cleanfilename)
                folder = fileparts(output);
                if ~isempty(folder)
                    output = [folder '\' cleanfilename];
                else
                    output = cleanfilename;
                end
            end
        end
        
        function filename = getCleanPartFilename(self, input)
            %Example: path\BRK\2MWbrkV05.007 -> path\BRK\2MWbrkV05.txt
            [~,filename,~] = fileparts(input);
            filename = self.getCleanFilename([filename '.txt']);
        end
        
        function output = getCleanProfileFilename(self, input)
            %Example: _profi49-PP_VG15m_V3.100 -> profi49-PP_VG15m.100
            [~,filename,ext] = fileparts(input);
            output = self.getCleanFilename([filename ext]);
        end
        
        function output = getCleanParameterFilename(self, input)
            %Example: VTS_PitchCtrl_V90_1,8MW_VCS-GridStreamer_params_002.csv -> PitchCtrl_V90_1,8MW_VCS-GridStreamer_params_002.csv
            [~,filename,ext] = fileparts(input);
            filename = [filename ext];
            
            if strcmpi(ext,'dll')
               if strfind(filename,'ProdCtrl')
                   output = 'ProdCtrl.dll';
               else
                   output = 'PitchCtrl.dll';
               end
            else
                if strfind(filename,'ProdCtrl')
                    filename = regexprep(filename, 'ProdCtrl','');
                    filename = ['ProdCtrl_' filename];
                elseif strfind(filename,'PitchCtrl')
                    filename = regexprep(filename, 'PitchCtrl','');
                    filename = ['PitchCtrl_' filename];
                end
                
                filename = strrep(filename,'VTS','');
                %filename = strrep(filename,'params','');
                filename = self.getCleanFilename(filename);
                filename = regexprep(filename, '_r[0-9]+[_][0-9]+_params[.]', '_params.');
                filename = strrep(filename, '.csv', '.txt');
                output = filename;
            end
        end
        
        function output = getCleanFilename(~, input)
            filename = regexprep(input, '_r[0-9]+[_][0-9]+[.]', '.');
            filename = regexprep(filename, '_ver[0-9]+[.]', '.');
            %filename = regexprep(filename, '@[0-9]+', '');
            filename = strrep(filename, '__', '_');
            filename = strrep(filename, '__', '_');
            filename = strrep(filename, '_.', '.');
            filename = regexprep(filename, '^_', '');
            output = filename;
        end
        
        function output = absolutePath(~, filename, relativetofolder)
            output = filename;
            
            if isempty(regexp(output, '(:|\\\\)', 'once'))
                if ~isempty(regexp(output, '\.\.','once'))
                    % Convert relative path to absolute path
                    [a,b,c] = fileparts(output);
                    output = fullfile(a,[b c]);
                    
                    if ~isempty(regexp(output, '\.\.','once'))
                        % Parts folder is relative to refmodel file
                        % Profiles/Parameters folder is relative to part file
                        % Rebmember to set the correct "relativetofolder"
                        [a,b,c] = fileparts([relativetofolder '\' output]);
                        output = fullfile(a,[b c]);
                        
                    end
                end
            end
        end
    end
end
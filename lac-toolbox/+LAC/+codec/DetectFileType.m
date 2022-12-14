classdef DetectFileType < handle
    methods
        function output = detect(self, name, proposedtype)
            output = '';
            
            %[folder,filename,ext] = fileparts(name);
            
            % if txt--> refmodel/part/profile/parameter
            % if BLD... in foldername -> part
            % if csv || dll--> parameter
            % isnumeric() --> profile/parameter
            
            
            % --> output = refmodel, part, profile, parameter
        end
    end
end
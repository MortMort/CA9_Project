classdef postloads < handle
% Codec class for reading and writing Postload files.
%
% Syntax:
%   postloadCodec=LAC.codec.postloads()
%   fid=fopen(filename)
%   s = postloadCodec(fid)
%   fclose(fid)
% 
% Supports decoding of:
%   RFO, LDD

    methods
        function self = postloads()
            self.filetypes = {'rfo','ldd','sst','mko'};
            self.category = [];
            self.filetype = [];
        end
        
        function output = getFileTypes(self)
            output = self.filetypes;
        end
        
        function Output = decode(self, FID)
            Output = struct();
            try
                % Detect type of part file and create codec obj
                a = eval(['LAC.scripts.MasterModel.misc.postloads.postloads_' lower(self.fileid2ComponentType(FID)) '();']);
                if isobject(a)
                    Output = a.decode(FID);
                end
            catch
                disp('Object not recognized')
            end
        end
        
        function encode(self, FID, data)
            Output = struct();
            try
                % Detect type of part file and create codec obj
                a = eval(['LAC.scripts.MasterModel.misc.postloads.postloads_' lower(self.fileid2ComponentType(FID)) '();']);
                if isobject(a)
                    Output = a.encode(FID, data);
                end
            end
        end
    end
    
    methods (Access=private)
        function componentType = fileid2ComponentType(self, FID)
            filename = fopen( FID );
            [~,fileName, componentType] = fileparts(filename);
            componentType=lower(strrep(componentType,'.',''));
            componentType=lower(strrep(componentType,' ',''));
            fileName=strrep(fileName,'.','');
            fileName=strrep(fileName,'.','');
            switch lower(fileName)
                case 'mainload'
                    componentType = 'mainload';
                case 'pitload'
                    componentType = 'pitload';
%                 case 'twrload'
%                     componentType = 'twrload';
                case 'twroffload'
                    componentType = 'twroffload';
                case 'drtload'
                    componentType = 'drtload';
            end
        end        
    end
    
    properties (Access=private)
        filetypes;
        category;
        filetype;
    end    
end
   
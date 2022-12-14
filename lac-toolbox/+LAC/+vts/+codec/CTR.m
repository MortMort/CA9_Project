classdef (Abstract) CTR < LAC.vts.codec.Part_Common
    methods (Static)
        function s = decode(VTSCoder)
            tmp = VTSCoder.search('ProductionControlInterfaceVersion');
            if isa(tmp,'cell')
                tmp = [tmp{:}];
            end
            tmp = strsplit_LMT(tmp,{' ','='});
            
            % Find number in line
            tmp_num = cellfun(@str2num, tmp,'UniformOutput',0);
            
            % Set interface version
            InterfaceVersion = num2str(tmp_num{~cellfun(@isempty,tmp_num)});       
            try
                s=feval([mfilename('class') 'v' InterfaceVersion]);
                s=s.decode(VTSCoder);
            catch e
                error('codec.Part_CTR:UnsupportedProdCtrlInterface', ['ProductionControlInterface version ' InterfaceVersion ' is not supported or ill formated'])
            end
            
            if ~isfield(s,'comments')
                [s.comments] = VTSCoder.getRemaininglines();
            end
        end
    end
    
    properties
        Header
        LowSpeedShaftOverspeedLimit, LowSpeedShaftOverspeedLimitReaction
        HighSpeedShaftOverspeedLimit, HighSpeedShaftOverspeedLimitReaction
        VOGLimit
        ProductionControlInterfaceVersion
        AuxDLLs
        CopyFiles
        comments
    end
    
    properties (Dependent=true, SetAccess=private)
        ProductionControllerParameters
        PitchControllerParameters
        SafetyPitchControllerParameters
        SafetyPitchHydraulicsParamteers
        TowerAccFilterParamteers
    end
    
%     methods
%         function decoded = get.ProductionControllerParameters(self)
%             decoded = [];
%             myfilename = self.AuxFiles('ProductionControllerParameters');
%             if ~exist(myfilename, 'file')
%                 myfilename = LAC.vts.shared.absolutepath(myfilename,fileparts(self.FileName),false);
%             end
%             if exist(myfilename, 'file')
%                 readerobj = LAC.codec.CodecTXT(myfilename);
%                 decoded = LAC.vts.codec.PARAMETER.decode(readerobj);
%             end
%         end
%         function decoded = get.PitchControllerParameters(self)
%             decoded = [];
%             myfilename = self.AuxFiles('PitchControllerParameters');
%             if ~exist(myfilename, 'file')
%                 myfilename = LAC.vts.shared.absolutepath(myfilename,fileparts(self.FileName),false);
%             end
%             if exist(myfilename, 'file')
%                 readerobj = LAC.codec.CodecTXT(myfilename);
%                 decoded = LAC.vts.codec.PARAMETER.decode(readerobj);
%             end
%         end
%         function decoded = get.SafetyPitchControllerParameters(self)
%             decoded = [];
%             myfilename = self.AuxFiles('SafetyPitchControllerParameters');
%             if ~exist(myfilename, 'file')
%                 myfilename = LAC.vts.shared.absolutepath(myfilename,fileparts(self.FileName),false);
%             end
%             if exist(myfilename, 'file')
%                 readerobj = LAC.codec.CodecTXT(myfilename);
%                 decoded = LAC.vts.codec.PARAMETER.decode(readerobj);
%             end
%         end
%         function decoded = get.SafetyPitchHydraulicsParamteers(self)
%             decoded = [];
%             myfilename = self.AuxFiles('SafetyPitchHydraulicsParamteers');
%             if ~exist(myfilename, 'file')
%                 myfilename = LAC.vts.shared.absolutepath(myfilename,fileparts(self.FileName),false);
%             end
%             if exist(myfilename, 'file')
%                 readerobj = LAC.codec.CodecTXT(myfilename);
%                 decoded = LAC.vts.codec.PARAMETER.decode(readerobj);
%             end
%         end
%         function decoded = get.TowerAccFilterParamteers(self)
%             decoded = [];
%             myfilename = self.AuxFiles('TowerAccFilterParamteers');
%             if ~exist(myfilename, 'file')
%                 myfilename = LAC.vts.shared.absolutepath(myfilename,fileparts(self.FileName),false);
%             end
%             if exist(myfilename, 'file')
%                 readerobj = LAC.codec.CodecTXT(myfilename);
%                 decoded = LAC.vts.codec.PARAMETER.decode(readerobj);
%             end
%         end
%     end    
    
     
end
   

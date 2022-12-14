classdef AuxDLL
   
    
    properties
        ControllerName
        SensorPrefix
        UpdateRate
        DLLfilename
        InterfaceFile
        ParamFilename
        InitCallName 
        UpdateCallName 
        TerminateCallName 
        OptionString   
    end
    
    properties (Dependent)
         Parameters
    end
    
    methods
        
        function s=AuxDLL(varargin)
            switch nargin
                case 1
                    d=varargin{1};
                    s.ControllerName=d.ControllerName;
                    s.UpdateRate=str2double(d.UpdateRate);
                    s.SensorPrefix=d.SensorPrefix;
                    s.DLLfilename=d.DLLfilename;
                    s.ParamFilename=d.ParamFilename;
                    s.InterfaceFile=d.InterfaceFile;
                    s.InitCallName = d.InitCallName; 
                    s.UpdateCallName=d.UpdateCallName;
                    s.TerminateCallName =d.TerminateCallName ;
                    s.OptionString = d.OptionString ;
            end
        end
        
        
        function p=get.Parameters(s)                
                coder=LAC.codec.VTSCodecLegacy(s.ParamFilename);
                p=LAC.vts.codec.AuxParameterFile.decode(coder);
        end
        
%         function s=set.ParamFilename(s,name)
%             s.ParamFilename=name;
%             
%             s.Parameters={}; %%This is a hack but on purpose
%         end
        
        
    end
    
end


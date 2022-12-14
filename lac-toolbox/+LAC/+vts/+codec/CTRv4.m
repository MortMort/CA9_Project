classdef CTRv4 < LAC.vts.codec.CTR
    methods (Static)
        function s = decode(VTSCoder)
            s = eval(mfilename('class'));
            %A check of IF versinos should be included
            s.ProductionControlInterfaceVersion = 4;
            s=s.decodeMe(VTSCoder);
            s.comments=VTSCoder.getRemaininglines();
        end
    end
    
    methods
        
         function s=CTRv4()
                s.AuxDLLs=LAC.vts.codec.AuxDLL.empty;
         end
         
        function dll=getAuxDLL(s,name)
            idx=strcmp(name,{s.AuxDLLs.ControllerName});
            dll=s.AuxDLLs(idx);
        end
         
        function status = encode(self, VTSCoder)
             VTSCoder.rewind();
             
             VTSCoder.initialize('part',mfilename, self.getAttributes());
               
             self.encodeHeader(VTSCoder);
             
             self.encodePitchAndProd(VTSCoder); 
             
             VTSCoder.setRemaininglines(self.comments);
             
             status = VTSCoder.save();
        end
        
        function paramSet=getParamSet(s)
            for k=1:length(s.AuxDLLs)
                paramSet(k).ControllerName=s.AuxDLLs(k).ControllerName;
                paramSet(k).Parameters=s.AuxDLLs(k).Parameters;
            end
        end

        function myattributes = getAttributes(self)

            %check matlab version
            [a dateb]  = version;
            datebnum = datenum(dateb);

            myattributes = struct();

            mco = metaclass(self);
            if datebnum > 734174
                myproperties = {mco.PropertyList(strcmpi({mco.PropertyList.SetAccess},'public')).Name};
            else
                for i = 1 : length(mco.Properties)
                    idx = 0;
                    if strcmpi(mco.Properties{i}.SetAccess,'public')
                        idx = idx + 1;
                        myproperties{i} = mco.Properties{i}.Name;
                    end
                end
            end            
            myproperties = myproperties(~strcmpi(myproperties,'AuxDLLS'));			
            mytables = {};
            myfiles = {};

            myattributes.properties = myproperties;
            myattributes.tables = mytables;
            myattributes.files = myfiles;
        end
    end
    methods (Access=protected)
        
        function encodePitchAndProd(self,VTSCoder)
             dll=self.getAuxDLL('ProductionController');
             VTSCoder.setLine('Production control');
             VTSCoder.setFile('ProductionController',30,dll.DLLfilename);
             VTSCoder.setFile('ProductionControllerParameters',30,dll.ParamFilename);
             
             dll=self.getAuxDLL('PitchController');
             VTSCoder.setLine('Pitch control');
             VTSCoder.setFile('PitchController',30,dll.DLLfilename);
             VTSCoder.setFile('PitchControllerParameters',30,dll.DLLfilename);
             
             VTSCoder.setLine('');
             VTSCoder.setProperty({num2str(self.ProductionControlInterfaceVersion)}, -34, 'ProductionControlInterfaceVersion');
             VTSCoder.setLine('');
        end
        
        function s=encodeHeader(s,VTSCoder)
             VTSCoder.setProperty(s.Header);
             VTSCoder.setLine('Supervision');
             VTSCoder.setProperty({s.LowSpeedShaftOverspeedLimit, s.LowSpeedShaftOverspeedLimitReaction}, 25, 'Low speed shaft overspeed limit [rpm], Reaction');
             VTSCoder.setProperty({s.HighSpeedShaftOverspeedLimit, s.HighSpeedShaftOverspeedLimitReaction}, 25, 'High speed shaft overspeed limit [rpm], Reaction');
             VTSCoder.setProperty({s.VOGLimit}, 25, 'VOG limit (LSS) [rpm]');
        end
        
        function s=decodeHeader(s,VTSCoder)
            VTSCoder.rewind();
            s.FileName = VTSCoder.getSource();
            [s.Type] = mfilename;
            
            [s.Header] =  VTSCoder.get(true);
            VTSCoder.skip(1);
            [s.LowSpeedShaftOverspeedLimit, s.LowSpeedShaftOverspeedLimitReaction] = VTSCoder.get();
            [s.HighSpeedShaftOverspeedLimit, s.HighSpeedShaftOverspeedLimitReaction] = VTSCoder.get();
            [s.VOGLimit] = VTSCoder.get();
        end
        
        function s=decodeMe(s,VTSCoder)
            s=s.decodeHeader(VTSCoder);
            s=s.decodeAuxDLL(VTSCoder);
        end
        
        function s=decodeAuxDLL(s,VTSCoder)
            
            dll=LAC.vts.codec.AuxDLL();
           
            dll.ControllerName='ProductionController';
            dll.SensorPrefix='pro';
            dll.UpdateRate=0.1;
            dll.InitCallName = 'Initialize';
            dll.UpdateCallName = 'Controller';
            dll.TerminateCallName = '';
            dll.OptionString = 'CheckInitializeReturnString';
            
            
            VTSCoder.search('ProductionController ');
            [~,dll.DLLfilename]=VTSCoder.getFile();
            
            DLLtxt = strrep(dll.DLLfilename, '.dll', '.txt');
            dll.InterfaceFile=DLLtxt;
         
            [~, parmfile] = VTSCoder.getFile();
            dll.ParamFilename=parmfile;
            
            
            s.AuxDLLs(1)=dll;
            
            
            %Clear temp struct
            dll=LAC.vts.codec.AuxDLL();
            
            dll.ControllerName='PitchController';
            dll.SensorPrefix='pit';
            dll.UpdateRate=0.01;
            dll.InitCallName = 'Initialize';
            dll.UpdateCallName = 'Controller';
            dll.TerminateCallName = '';
            dll.OptionString = 'CheckInitializeReturnString';
            
            
            VTSCoder.search('ProductionController ');
            [~,dll.DLLfilename]=VTSCoder.getFile();
            
            DLLtxt = strrep(dll.DLLfilename, '.dll', '.txt');
            dll.InterfaceFile=DLLtxt;
         
            [~, parmfile] = VTSCoder.getFile();
            dll.ParamFilename=parmfile;
            s.AuxDLLs(2)=dll;
            
            [~,no]=VTSCoder.search('ProductionControlInterfaceVersion');
            VTSCoder.jump(no(end)+1);
        end

    end
end
   

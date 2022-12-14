 classdef CTRv7 < LAC.vts.codec.CTRv6
    methods (Static)
        function s = decode(VTSCoder)
            s = eval(mfilename('class'));
            %A check of IF versinos should be included
            s.ProductionControlInterfaceVersion = 7;
            s=s.decodeMe(VTSCoder);
            s.comments=VTSCoder.getRemaininglines();
        end
        
        function s = decodeInterfaceFile(VTSCoder)
            s = eval(mfilename('class'));
            s.ProductionControlInterfaceVersion = 7;
            s = s.decodeAuxDLL(VTSCoder);
            s.comments = VTSCoder.getRemaininglines();
        end
    end
    
    
    methods
        function status=encode(s,VTSCoder)
             VTSCoder.rewind();
             VTSCoder.initialize('part',mfilename, s.getAttributes());
             
             s.encodeHeader(VTSCoder);
             VTSCoder.setLine('');
                
             VTSCoder.setProperty({num2str(s.ProductionControlInterfaceVersion)}, -34, 'ProductionControlInterfaceVersion');
             VTSCoder.setLine('');
             
             s.encodeAuxDLLCnvCmd(VTSCoder);            
             s.encodeAuxDLL(VTSCoder);
             s.encodeInterface(VTSCoder);
             VTSCoder.setRemaininglines(s.comments);
             status = VTSCoder.save(); 
        end
    end
        


    methods (Access=protected)
        
        function s = decodeAuxDLL(s,VTSCoder)
            
            s = s.decodeAuxDLLCnvCmd(VTSCoder);
            
            dlltxt=VTSCoder.search('AuxDLL ');
            %AuxDLL <ControllerName> <DLLfilename> <ParamFilename> <InitCallName> <UpdateCallName> <TerminateCallName> <UpdateRate> <OptionString>
            dlls    = regexp(dlltxt,'AuxDLL\s+(?<ControllerName>\w+)\s+(?<DLLfilename>\S+)\s+(?<ParamFilename>\S+)\s+(?<InitCallName>\S+)\s+(?<UpdateCallName>\S+)\s+(?<TerminateCallName>\S+)\s+(?<UpdateRate>[\d\.]+)\s+(?<OptionString>\S+)','names');
            
            for i = 1: length(dlls)
                txtFile = strrep( dlls{i}.DLLfilename, '.dll', '.txt');
                dlls{i}.InterfaceFile=txtFile;
                dlls{i}.SensorPrefix=dlls{i}.ControllerName(1:3);
                s.AuxDLLs(end+1)=LAC.vts.codec.AuxDLL(dlls{i});              
            end
           
            s = s.decodeAuxDLLInterface(VTSCoder);
            s = s.decodeCopyFiles(VTSCoder);
            
            [~,no]=VTSCoder.search('Interface ');
            
            [~,noCopyFiles]=VTSCoder.search('COPYFILE ');
            if noCopyFiles(end) > no(end)
                no = noCopyFiles;
            end
            
            VTSCoder.jump(no(end)+1);
        end
        
        function encodeAuxDLL(s,VTSCoder)
            for k = 1: length(s.AuxDLLs)
                str=sprintf('AuxDLL %s %s %s %s %s %s %1.2f %s',...
                    s.AuxDLLs(k).ControllerName,...
                    s.AuxDLLs(k).DLLfilename,...
                    s.AuxDLLs(k).ParamFilename,...
                    s.AuxDLLs(k).InitCallName,...
                    s.AuxDLLs(k).UpdateCallName,...
                    s.AuxDLLs(k).TerminateCallName,...
                    s.AuxDLLs(k).UpdateRate,...
                    s.AuxDLLs(k).OptionString);
                VTSCoder.setLine(str);
            end
        end
        
       
    end
end
   

classdef CTRv6 < LAC.vts.codec.CTRv5
    
    
    properties
         CnvCmdTrInit     
         CnvCmdTrOff      
         CnvCmdTrDcOn          
         CnvCmdTrConnected     
         CnvCmdTrDisconnecting 
         Interface
    end
    
    methods (Static)
        function s = decode(VTSCoder)
            s = eval(mfilename('class'));
            %A check of IF versinos should be included
            s.ProductionControlInterfaceVersion = 6;
            s=s.decodeMe(VTSCoder);
            s.comments=VTSCoder.getRemaininglines();            
        end
    end
    
    methods
        function status = encode(s, filename)
             VTSCoder = LAC.codec.CodecTXT(filename);
             VTSCoder.rewind();
             VTSCoder.initialize('part',mfilename, s.getAttributes());
             s.encodeHeader(VTSCoder);
             s.encodePitchAndProd(VTSCoder); 
             VTSCoder.setLine('');
             s.encodeAuxDLLCnvCmd(VTSCoder);
             s.encodeAuxDLL(VTSCoder);
             s.encodeInterface(VTSCoder);
             VTSCoder.setRemaininglines(s.comments);
             status = VTSCoder.save();           
        end
    end
    
    methods (Access=protected)
         
        function encodeInterface(s,VTSCoder)
            for i = 1: length(s.Interface)
                VTSCoder.setLine(['Interface ' sprintf('%-6s', s.Interface{i,1}), ' ', sprintf('%-6s', s.Interface{i,2}), ' ', strjoin_LMT(s.Interface(i,3:end), ' ')]);
             end
        end
        function encodeAuxDLLCnvCmd(s,VTSCoder)
            VTSCoder.setLine('AuxDLLInfo');
            VTSCoder.setLine(sprintf('%d %d %d %d %d %s',s.CnvCmdTrInit, s.CnvCmdTrOff, s.CnvCmdTrDcOn, s.CnvCmdTrConnected, s.CnvCmdTrDisconnecting, ' Converter command transformation (Init, Off, DcOn, Connected, Disconnecting)'));            
        end
        
        function s=decodeAuxDLL(s,VTSCoder)
            s = s.decodeAuxDLL@LAC.vts.codec.CTRv5(VTSCoder);
          
            s = s.decodeAuxDLLCnvCmd(VTSCoder);
            
            dlltxt=VTSCoder.search('AuxDLL ');
            %AuxDLL <ControllerName> <DLLfilename> <ParamFilename> <SensorPrefix> <UpdateRate>
            dlls    = regexp(dlltxt, 'AuxDLL\s+(?<ControllerName>\w+)\s+(?<DLLfilename>[A-Za-z0-9:,.\\/_-+]+)\s+(?<ParamFilename>[A-Za-z0-9:,.\\/_-+]+)\s+(?<SensorPrefix>\w+)\s+(?<UpdateRate>[\d.]+)','names');
            
            for i = 1: length(dlls)
                txtFile = strrep( dlls{i}.DLLfilename, '.dll', '.txt');
                dlls{i}.InterfaceFile=txtFile;
                dlls{i}.InitCallName = 'Initialize';
                dlls{i}.UpdateCallName = 'Controller';
                dlls{i}.TerminateCallName = '';
                dlls{i}.OptionString = 'CheckInitializeReturnString';
                s.AuxDLLs(end+1)=LAC.vts.codec.AuxDLL(dlls{i});              
            end

            s = s.decodeAuxDLLInterface(VTSCoder);
            
            [~,no]=VTSCoder.search('Interface ');
            VTSCoder.jump(no(end)+1);
        end
        
        function s=decodeAuxDLLCnvCmd(s,VTSCoder)
            VTSCoder.search('AuxDLLInfo');
            VTSCoder.skip(1);
            cmdtxt=VTSCoder.get(true);
            CnvCmd = regexp(cmdtxt, '^(?<CnvCmdTrInit>[\d]+)\s+(?<CnvCmdTrOff>[\d]+)\s+(?<CnvCmdTrDcOn>[\d]+)\s+(?<CnvCmdTrConnected>[\d]+)\s+(?<CnvCmdTrDisconnecting>[\d]+)\s+\w+','names');
            if ~isempty(CnvCmd)
                s.CnvCmdTrInit          = str2double(CnvCmd.CnvCmdTrInit);
                s.CnvCmdTrOff           = str2double(CnvCmd.CnvCmdTrOff);
                s.CnvCmdTrDcOn          = str2double(CnvCmd.CnvCmdTrDcOn);
                s.CnvCmdTrConnected     = str2double(CnvCmd.CnvCmdTrConnected);
                s.CnvCmdTrDisconnecting = str2double(CnvCmd.CnvCmdTrDisconnecting);
            end
        end
        
        function s=decodeAuxDLLInterface(s,VTSCoder)
            
            % The order of lines in the AuxDLLInfo section changes.
            % Need to read the remaining of the file
            iftxt=VTSCoder.search('Interface ');
            
            %strjoin to get an aaray as output
            Ifdef = regexp(strjoin_LMT(iftxt','\n'), 'Interface\s+(?<name1>\S+)\s+(?<name2>\S+)\s+(?<value1>[\d.-+e]+)\s+(?<value2>[\d.-+e]+)\s+(?<value3>[\d.-+e]+)\s+(?<value4>[\d.-+e]+)\s+(?<value5>[\d.-+e]+)','names');
            s.Interface = {Ifdef.name1; Ifdef.name2; Ifdef.value1; Ifdef.value2; Ifdef.value3; Ifdef.value4; Ifdef.value5}';
            
        end
        
        function s=decodeCopyFiles(s,VTSCoder)
            
            iftxt=VTSCoder.search('COPYFILE ');
            if ~isempty(iftxt)
				Ifdef = regexp(strjoin_LMT(iftxt','\n'), 'COPYFILE\s+(?<SourceDirectory>\S+)\s+(?<TargetName>\S+)','names');
				s.CopyFiles = {Ifdef.SourceDirectory; Ifdef.TargetName}';
			end
            
        end



        
         function encodeAuxDLL(s,VTSCoder)
            %Find indices for pitch and production controller
            l=regexp({s.AuxDLLs.ControllerName},'^ProductionController|^PitchController');
            
            %Creaty struct array without pitch and production controller
            dlls=s.AuxDLLs(cellfun(@isempty,l));
            
            % Add everything else than ProductionController and PitchController
            for k = 1: length(dlls)
                str=sprintf('AuxDLL %s %s %s %s %1.2f',...
                    dlls(k).ControllerName,...
                    dlls(k).DLLfilename,...
                    dlls(k).ParamFilename,...
                    dlls(k).SensorPrefix,...
                    dlls(k).UpdateRate);
                VTSCoder.setLine(str);
            end
         end
    end
end
   

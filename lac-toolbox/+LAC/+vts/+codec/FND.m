classdef FND < LAC.vts.codec.Part_Common
    methods (Static)
        function s = decode(VTSCoder)
            VTSCoder.rewind();
            s = eval(mfilename('class'));
            
            [s.FileName] = VTSCoder.getSource();
            [s.Type] = mfilename;
            
            [s.Header] = VTSCoder.get(true);
            [s.logdecr,s.Fref] = VTSCoder.get();
            [s.rhofndx,s.mcor,s.Efndx] = VTSCoder.get();
            
            tHeader = VTSCoder.readTableHeader();
            if ~isempty(tHeader)
                tmp = strsplit_LMT(tHeader{1});
                s.FoundationTable{1} = VTSCoder.readTableData(str2double(tmp{1}),7);
                s.FoundationTable{1}.columnnames = tmp(2:end);
            else
                s.FoundationTable{1} = VTSCoder.readTableData('','');
            end
            
            [s.Filled,s.rho] = VTSCoder.get();
            
            [s.comments] = VTSCoder.getRemaininglines();
            
            s = s.convertAllToNumeric();
            
            % Detect glb_damping option inside the comments
            split_comments = strsplit_LMT(s.comments);
            i = 1;
            while i < length(split_comments) && ~strcmp(split_comments{i},'glb_damping')
                i = i + 1;
            end
            if i < length(split_comments)
                if strcmp(split_comments{i+1},'Rayleigh')
                    s.glb_damping_method = 'glb_damping Rayleigh';
                    for j = 1:4
                        s.glb_damping_array(end+1) = str2double(split_comments{i+1+j});
                    end
                else
                    s.glb_damping_method = 'glb_damping';
                    j = 1;
                    while i+j <= length(split_comments)
                        num = str2double(split_comments{i+j});
                        if isnan(num)
                            break
                        end
                        s.glb_damping_array(end+1) = num;
                        j = j + 1;
                    end
                end
            else
                s.glb_damping_method = 'None';
                s.glb_damping_array = 0;
            end
            s.glb_method_private = s.glb_damping_method;
            s.glb_array_private = s.glb_damping_array;
        end
    end
    
    methods
        function encode(self,filename)
            if ~strcmp(self.glb_method_private, self.glb_damping_method) || ...
                min(self.glb_array_private == self.glb_damping_array) == 0
                warning('Modifying glb_damping in Matlab will not affect the PARTS file. To do this you must change the comment attribute.')
            end
            
            VTSCoder = LAC.codec.CodecTXT(filename);
            VTSCoder.rewind();
            
            VTSCoder.initialize('part',mfilename, self.getAttributes());
            self = self.convertAllToString();
            
            VTSCoder.setProperty(self.Header);
            VTSCoder.setProperty({self.logdecr,self.Fref}, 27, 'log.decr, Fref (Hz)');
            VTSCoder.setProperty({self.rhofndx,self.mcor,self.Efndx}, 27, 'rhofndx  mcor  Efndx');
            
            tHeader = strjoin_LMT([num2str(size(self.FoundationTable{1}.data,1)) self.FoundationTable{1}.columnnames],'   ');
            VTSCoder.setLine(tHeader);
            VTSCoder.writeTableData(self.FoundationTable{1},'%8.1f');
            
            VTSCoder.setProperty({self.Filled,self.rho}, 27, 'Filled (1/0) rho');
            VTSCoder.setRemaininglines(self.comments);
            
            status = VTSCoder.save();
        end
        
        function myattributes = getAttributes(self)
            myattributes = struct();
            
            mco = metaclass(self);
            myproperties = {mco.PropertyList(strcmpi({mco.PropertyList.SetAccess},'public')).Name};
            myproperties = myproperties(~strcmpi(myproperties,'FoundationTable')); % FoundationTable is not a property
            mytables = {'FoundationTable'};
            myfiles = {};
                
            myattributes.properties = myproperties;
            myattributes.tables = mytables;
            myattributes.files = myfiles;
        end
    end        
    
    properties
        Header
        logdecr,Fref
        rhofndx,mcor,Efndx
        FoundationTable
        Filled,rho
        glb_damping_method,glb_damping_array
        comments
    end
    
    properties (Access = private)
        glb_method_private,glb_array_private
    end
end

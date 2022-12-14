classdef GENv1 < LAC.vts.codec.GEN
    methods (Static)
        function s = decode(VTSCoder)
            VTSCoder.rewind();
            s = eval(mfilename('class'));
            [s.FileName] = VTSCoder.getSource();
            [s.Type] = mfilename;
            
            [s.Header] = VTSCoder.get(true);
            [s.GeneratorInertia]               = VTSCoder.get();
            [s.Polepairs, s.Fnet, s.ConstLoss] = VTSCoder.get();
            [s.TGridErr, s.HFTorgue]           = VTSCoder.get();
            [s.PelRtd, s.GenRpmRtd]            = VTSCoder.get();
            
            function [table] = myTableReader()
                tHeader = VTSCoder.readTableHeader();
                tmp = VTSCoder.lines(VTSCoder.current,VTSCoder.current+1);
                if ~isempty(tmp)
                    VTSCoder.skip(2);
                    rowcol = str2double(strsplit_LMT(tmp{1}));
                    table = VTSCoder.readTableData(rowcol(1), rowcol(2)+1);
                    table.columnnames = strsplit_LMT(strtrim(tmp{2}));
                    table.rownames = table.data(:,1);
                    table.data = table.data(:,2:end);
                    table.header = tHeader;
                else
                    table = VTSCoder.readTableData('','');
                    table.header = tHeader;
                end
            end
            
            VTSCoder.search('Generator 1');
            VTSCoder.skip(1);
            s.Generator1Table{1} = myTableReader();
            s.Generator1Table{2} = myTableReader();
            
            VTSCoder.search('Generator 2');
            VTSCoder.skip(1);
            s.Generator2Table{1} = myTableReader();
            s.Generator2Table{2} = myTableReader();
            
            [s.Psc, s.dtsc] = VTSCoder.get();
            
            VTSCoder.search('AuxLossTable');
            s.AuxLossTable{1}  = myTableReader();
            
            [s.comments] = VTSCoder.getRemaininglines();
        end
    end
    
    methods
        function status = encode(self, filename)
            VTSCoder = LAC.codec.CodecTXT(filename);
            VTSCoder.rewind();
            
            VTSCoder.initialize('part',mfilename, self.getAttributes());
            self = self.convertAllToString();
            
            VTSCoder.setProperty(self.Header);
            
            VTSCoder.setProperty({self.GeneratorInertia}, 31, 'Generator inertia');
            VTSCoder.setProperty({self.Polepairs, self.Fnet, self.ConstLoss}, 31, 'Polepairs, fnet,const_loss');
            VTSCoder.setProperty({self.TGridErr, self.HFTorgue}, 31, 'TGridErrHFTorgue[]');
            VTSCoder.setProperty({self.PelRtd, self.GenRpmRtd}, 31, 'PelRtd GenRpmRtd');
            
            function myTableWriter(table)
                VTSCoder.writeTableHeader(table.header);
                table.data = [[{''} table.rownames']' [table.columnnames' table.data']'];
                [rows,cols] = size(table.data);
                VTSCoder.setLine(sprintf('%d %d',rows-1, cols-1));
                VTSCoder.writeTableData(table,'%8.1f');
            end
            
            VTSCoder.setLine('Generator 1')
            myTableWriter(self.Generator1Table{1})
            myTableWriter(self.Generator1Table{2})
            
            VTSCoder.setLine('Generator 2')
            myTableWriter(self.Generator2Table{1})
            myTableWriter(self.Generator2Table{2})
            
            VTSCoder.setProperty({self.Psc, self.dtsc}, 31, 'Psc dtsc');
            
            myTableWriter(self.AuxLossTable{1})
            %VTSCoder.writeTableHeader(self.AuxLossTable{1}.header);
            %[rows,cols] = size(self.AuxLossTable{1}.data);
            %VTSCoder.setLine(sprintf('%d %d',rows, cols));
            %VTSCoder.writeTableData(self.AuxLossTable{1},'%8.1f');
            
            VTSCoder.setRemaininglines(self.comments);
            
            status = VTSCoder.save();
        end
        
        function myattributes = getAttributes(self)
            myattributes = struct();
            
            mco = metaclass(self);
            myproperties = {mco.PropertyList(strcmpi({mco.PropertyList.SetAccess},'public')).Name};
            myproperties = myproperties(~strcmpi(myproperties,'Generator1Table'));
            myproperties = myproperties(~strcmpi(myproperties,'Generator2Table'));
            myproperties = myproperties(~strcmpi(myproperties,'ACDumpLoadTable')); 
            myproperties = myproperties(~strcmpi(myproperties,'AuxLossTable')); 
            
            % GENv2 properties
            myproperties = myproperties(~strcmpi(myproperties,'DelayTime')); 
            myproperties = myproperties(~strcmpi(myproperties,'TorqueRef')); 
            myproperties = myproperties(~strcmpi(myproperties,'TorqueFraction')); 
            myproperties = myproperties(~strcmpi(myproperties,'Capacity')); 
            
            mytables = {'Generator1Table','Generator2Table','AuxLossTable'};
            myfiles = {};
            
            myattributes.properties = myproperties;
            myattributes.tables = mytables;
            myattributes.files = myfiles;
        end
    end        
    
end

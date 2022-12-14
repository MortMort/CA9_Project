classdef GENv2 < LAC.vts.codec.GEN
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
            
            VTSCoder.search('ACDUMPLOAD');
            VTSCoder.skip(1);
            [s.DelayTime, s.TorqueRef, s.TorqueFraction] = VTSCoder.get();
            [s.Capacity]                       = VTSCoder.get();
            
            nRows = 0;
            tmp = VTSCoder.lines(VTSCoder.current,VTSCoder.current);
            if ~isempty(tmp)
                VTSCoder.skip(1);
                nRows = strsplit_LMT(tmp{1});
                nRows = nRows{1};
                if ischar(nRows)
                    nRows = str2double(nRows);
                end
            end
            s.ACDumpLoadTable{1} = VTSCoder.readTableData(nRows,2);
            s.ACDumpLoadTable{1}.columnnames   = {'x','y'};
            s.ACDumpLoadTable{1}.header = {'ACDUMPLOAD'};
            
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
            
            function myTableWriter(table, comment)
                [rows,cols] = size(table.data);
                VTSCoder.setLine(strtrim(sprintf('%d %d                             %s',rows, cols, comment)));
                VTSCoder.writeTableData(table,'%8.1f');
            end
            
            VTSCoder.setLine('Generator 1')
            VTSCoder.writeTableHeader(self.Generator1Table{1}.header);
            myTableWriter(self.Generator1Table{1}, 'Rows Columns Electrical efficiency table')
            VTSCoder.writeTableHeader(self.Generator1Table{2}.header);
            myTableWriter(self.Generator1Table{2}, 'Rows Columns Mechanical efficiency table')
            
            VTSCoder.setLine('Generator 2')
            VTSCoder.writeTableHeader(self.Generator2Table{1}.header);
            myTableWriter(self.Generator2Table{1}, 'Rows Columns Electrical efficiency table')
            VTSCoder.writeTableHeader(self.Generator2Table{2}.header);
            myTableWriter(self.Generator2Table{2}, 'Rows Columns Mechanical efficiency table')
            
            VTSCoder.setProperty({self.Psc, self.dtsc}, 31, 'Psc dtsc');
            
            VTSCoder.writeTableHeader(self.ACDumpLoadTable{1}.header);
            VTSCoder.setProperty({self.DelayTime, self.TorqueRef, self.TorqueFraction}, 31, 'Delay time, Torque_ref [nm], torque fraction during delay');
            VTSCoder.setProperty({self.Capacity}, 31, 'Capacity');
            [rows,cols] = size(self.ACDumpLoadTable{1}.data);
            VTSCoder.setLine(strtrim(sprintf('%d           number of data points',rows)));
            VTSCoder.writeTableData(self.ACDumpLoadTable{1},'%8.1f');
            
            VTSCoder.setLine('');
            VTSCoder.setLine('');
            VTSCoder.writeTableHeader(self.AuxLossTable{1}.header);
            myTableWriter(self.AuxLossTable{1}, 'Rows Columns')
            
            VTSCoder.setRemaininglines(self.comments);
            
            status = VTSCoder.save();
        end
        
        function myattributes = getAttributes(self)
            myattributes = struct();
            
            mco = metaclass(self);
            myproperties = {mco.PropertyList(strcmpi({mco.PropertyList.SetAccess},'public')).Name};
            myproperties = myproperties(~strcmpi(myproperties,'Generator1Table'));
            myproperties = myproperties(~strcmpi(myproperties,'Generator2Table'));
            myproperties = myproperties(~strcmpi(myproperties,'AuxLossTable')); 
            myproperties = myproperties(~strcmpi(myproperties,'ACDumpLoadTable')); 
            
            mytables = {'Generator1Table','Generator2Table','ACDumpLoadTable','AuxLossTable'};
            myfiles = {};
            
            myattributes.properties = myproperties;
            myattributes.tables = mytables;
            myattributes.files = myfiles;
        end
    end        
    
end

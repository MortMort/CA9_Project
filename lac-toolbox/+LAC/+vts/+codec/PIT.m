classdef PIT < LAC.vts.codec.Part_Common
    methods (Static)
        function s = decode(VTSCoder)
            VTSCoder.rewind();
            s = eval(mfilename('class'));
            
            [s.FileName] = VTSCoder.getSource();
            [s.Type] = mfilename;
            
            [s.Header] = VTSCoder.get(true);
            [s.order,s.timeconst,s.Ksi,s.tpsdelay,s.Deadband] = VTSCoder.get();
            [s.PistonPosxMin1,s.PistonPosxMin2,s.PistonPosxMin3,s.PistonPosxMax1,s.PistonPosxMax2,s.PistonPosxMax3] = VTSCoder.get();
            [s.PiMinG1,s.PiMinG2,s.PiMinG3,s.PiMaxG1,s.PiMaxG2,s.PiMaxG3] = VTSCoder.get();
            [s.tupd0,s.tupd1,s.tupd2] = VTSCoder.get();
            [s.EMCpitchspeedresp,s.Frequency,s.DampingRatio] = VTSCoder.get();
            
            function [table] = myTableReader()
                %tHeader = VTSCoder.readTableHeader();
                tmp = VTSCoder.lines(VTSCoder.current,VTSCoder.current+1);
                if ~isempty(tmp)
                    VTSCoder.skip(2);
                    rowcol = str2double(strsplit_LMT(tmp{1}));
                    table = VTSCoder.readTableData(rowcol(1), rowcol(2)+1);
                    table.columnnames = strsplit_LMT(strtrim(tmp{2}));
                    table.rownames = table.data(:,1);
                    table.data = table.data(:,2:end);
                    %table.header = tHeader;
                else
                    table = VTSCoder.readTableData('','');
                    %table.header = tHeader;
                end
            end
            
            s.Tables{1} = myTableReader();
            %s.Tables{1}.columnnames = {'H','D','t','M','Cd','Cm','Out'};
            
            s.Tables{2} = myTableReader();
            %s.Tables{2}.columnnames = {'H','D','t','M','Cd','Cm','Out'};
            
            [s.a_0] = VTSCoder.get();
            [s.a_1] = VTSCoder.get();
            [s.a_2] = VTSCoder.get();
            [s.a_3] = VTSCoder.get();
            [s.a_4] = VTSCoder.get();
            [s.PosVgain,s.PosOffset] = VTSCoder.get();
            [s.Theta_k] = VTSCoder.get();
            [s.c_pitch_1,s.c_pitch_2] = VTSCoder.get();
            [s.c_pitch_3,s.c_pitch_4] = VTSCoder.get();
            [s.TBD1,s.TBD2] = VTSCoder.get();
            
            [s.comments] = VTSCoder.getRemaininglines();
            
            s = s.convertAllToNumeric();
        end
    end
    
    methods
        function encode(self,filename)
            VTSCoder = LAC.codec.CodecTXT(filename);
            VTSCoder.rewind();
            
            VTSCoder.initialize('part',mfilename, self.getAttributes());
            self = self.convertAllToString();
            
            VTSCoder.setProperty(self.Header);
            VTSCoder.setProperty({self.order,self.timeconst,self.Ksi,self.tpsdelay,self.Deadband}, 39, 'order timeconst[s]/f0[Hz] -/Ksi tpsdelay[s] Deadband [deg]');
            VTSCoder.setProperty({self.PistonPosxMin1,self.PistonPosxMin2,self.PistonPosxMin3,self.PistonPosxMax1,self.PistonPosxMax2,self.PistonPosxMax3}, 39, ' Xmin1 Xmin2 Xmin3 Xmax1 Xmax2 Xmax3 [mm]');
            VTSCoder.setProperty({self.PiMinG1,self.PiMinG2,self.PiMinG3,self.PiMaxG1,self.PiMaxG2,self.PiMaxG3}, 39, ' PiMin1 PiMin2 PiMin3 PiMax1 PiMax2 PiMax2 [deg]');
            VTSCoder.setProperty({self.tupd0,self.tupd1,self.tupd2}, 39, 'tupd0 (STOP/EMC) [s]');
            VTSCoder.setProperty({self.EMCpitchspeedresp,self.Frequency,self.DampingRatio}, 39, 'On/Off switch for 2nd order pitch speed response [-]; Frequency second order pitch response filter [Hz]; Damping ratio of second order response filter [-]');
            
            function myTableWriter(table,comment)
                table.data = [[{''} table.rownames']' [table.columnnames' table.data']'];
                [rows,cols] = size(table.data);
                VTSCoder.setLine(sprintf('%d %d %s',rows-1, cols-1,comment));
                VTSCoder.writeTableData(table,'%8.1f');
            end
            
            myTableWriter(self.Tables{1},'ProductionTable: Nrows and Ncolumns (not including pitch moment and control voltage); Top row=pitch moments, subsequent rows=ControlVoltage and then pitch rates')
            myTableWriter(self.Tables{2},'EmergencyTable: Nrows and Ncolumns (not including pitch moment and control voltage); Top row=pitch moments, subsequent rows=ControlVoltage and then pitch rates')
            
            VTSCoder.setProperty({self.a_0}, 21, 'a_0');
            VTSCoder.setProperty({self.a_1}, 21, 'a_1');
            VTSCoder.setProperty({self.a_2}, 21, 'a_2');
            VTSCoder.setProperty({self.a_3}, 21, 'a_3');
            VTSCoder.setProperty({self.a_4}, 21, 'a_4');
            VTSCoder.setProperty({self.PosVgain,self.PosOffset}, 21, 'PosVgain PosOffset');
            VTSCoder.setProperty({self.Theta_k}, 21, 'Theta_k {vinkel hvor der skiftes kalibreringskurve 1->2}');
            VTSCoder.setProperty({self.c_pitch_1,self.c_pitch_2}, 21, 'c_pitch_1 c_pitch_2 parametre til kalibreringskurve 1');
            VTSCoder.setProperty({self.c_pitch_3,self.c_pitch_4}, 21, 'c_pitch_3 c_pitch_4 parametre til kalibreringskurve 2');
            VTSCoder.setProperty({self.TBD1,self.TBD2}, 21, '');
            
            VTSCoder.setRemaininglines(self.comments);
            
            status = VTSCoder.save();
        end
        
        function myattributes = getAttributes(self)
            myattributes = struct();
            
            mco = metaclass(self);
            myproperties = {mco.PropertyList(strcmpi({mco.PropertyList.SetAccess},'public')).Name};
            myproperties = myproperties(~strcmpi(myproperties,'Tables')); % FoundationTable is not a property
            mytables = {'Tables'};
            myfiles = {};
            
            myattributes.properties = myproperties;
            myattributes.tables = mytables;
            myattributes.files = myfiles;
        end
    end        
    
    properties
        Header
        order,timeconst,Ksi,tpsdelay,Deadband
        PistonPosxMax1,PistonPosxMax2,PistonPosxMax3,PistonPosxMin1,PistonPosxMin2,PistonPosxMin3
        PiMinG1,PiMinG2,PiMinG3,PiMaxG1,PiMaxG2,PiMaxG3
        tupd0,tupd1,tupd2
        EMCpitchspeedresp,Frequency,DampingRatio
        Tables
        a_0
        a_1
        a_2
        a_3
        a_4
        PosVgain,PosOffset
        Theta_k
        c_pitch_1,c_pitch_2
        c_pitch_3,c_pitch_4
        TBD1,TBD2
        comments
    end
end

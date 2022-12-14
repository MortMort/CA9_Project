classdef ERR < LAC.vts.codec.Part_Common
    methods (Static)
        function s = decode(VTSCoder)
            VTSCoder.rewind();
            s = eval(mfilename('class'));
            
            [s.FileName] = VTSCoder.getSource();
            [s.Type] = mfilename;
            
            [s.Header] = VTSCoder.get(true);
            
            s.MaxMinTable = {};
            for k = 0:100
                % Skip blank lines
                currentlineno = VTSCoder.current();
                for i=0:10
                    currentline = VTSCoder.lines(currentlineno+i,currentlineno+i);
                    if isempty(currentline)
                        break;
                    elseif isempty(strtrim(currentline{1}))
                        VTSCoder.skip(1);
                    else
                        break;
                    end
                end
                
                %nextline = VTSCoder.lines(currentlineno+i,currentlineno+i);
                SectionName = VTSCoder.readTableHeader();

                
                noOfRows = 0;
                currentlineno = VTSCoder.current();
                startline = VTSCoder.lines(currentlineno,currentlineno);
                
                if ~isempty(startline)
                    % This is an TXT file
                    if length(strsplit_LMT(startline{1}))==1
                        SectionName = VTSCoder.readTableHeader();
                        currentlineno = VTSCoder.current();
                    end
                    
                    % Find number of rows
                    for i=0:100
                        nextline = VTSCoder.lines(currentlineno+i,currentlineno+i);
                        if ~isempty(nextline)
                            if isempty(nextline{1})
                                break;
                            elseif length(strsplit_LMT(nextline{1}))<5
                                % TBD: Skip empty and "----------" lines
                                %disp(VTSCoder.lines(currentlineno+i-2,currentlineno+i))
                                break;
                            else
                                noOfRows = noOfRows+1;
                            end
                        else
                            break;
                        end
                        
                    end
                end
                
                tmp2 = VTSCoder.readTableData(noOfRows,'4');
                if ~isempty(tmp2.data)
                    if isempty(s.MaxMinTable)
                        s.MaxMinTable{1}.data = [repmat(SectionName, [size(tmp2.data,1) 1]) tmp2.data];
                        s.MaxMinTable{1}.comments = tmp2.comments;
                    else
                        s.MaxMinTable{1}.data = [s.MaxMinTable{1}.data; [repmat(SectionName, [size(tmp2.data,1) 1]) tmp2.data]];
                        s.MaxMinTable{1}.comments = [s.MaxMinTable{1}.comments; tmp2.comments];
                    end
                end
            end
            s.MaxMinTable{1}.columnnames = {'Section','Name','Min','Max','Dummy'};
            
            [s.comments] = VTSCoder.getRemaininglines();
            s = s.convertAllToNumeric();
        end
    end
    
    methods
        function status = encode(self, VTSCoder)
            VTSCoder.rewind();
            
            VTSCoder.initialize('part',mfilename, self.getAttributes());
            self = self.convertAllToString();
            
            VTSCoder.setProperty(self.Header);
            
            tmptable = struct();
            sectionnames = {'CLIMATE','iec','dk','dibt','nl','special','TXTFILE','speeds','init','code words','SEA','BLADE','HUBEXT.','HUB','NACELLE','YAW (not checked)','TOWER','FOUNDATN','DR.TRAIN','GENERATOR','BRAKE','PITCH'};
            for i = 1:length(sectionnames)
                if strcmpi('TXTFILE',sectionnames{i})
                    VTSCoder.setLine(sectionnames{i});
                else
                    idx = strcmpi(self.MaxMinTable{1}.data(:,1),sectionnames{i});
                    tmptable.data = self.MaxMinTable{1}.data(idx,:);
                    tmptable.data = tmptable.data(:,2:end);
                    tmptable.comments = self.MaxMinTable{1}.comments(idx,:);
                    tmptable.columnnames = self.MaxMinTable{1}.columnnames(2:end);

                    VTSCoder.writeTableHeader({sectionnames{i}});
                    VTSCoder.writeTableData(tmptable, '%3.1f');
                end
            end
            VTSCoder.setRemaininglines(self.comments);
            
            status = VTSCoder.save();
        end
        
        function myattributes = getAttributes(self)
            myattributes = struct();
            
            mco = metaclass(self);
            myproperties = {mco.PropertyList(strcmpi({mco.PropertyList.SetAccess},'public')).Name};
            myproperties = myproperties(~strcmpi(myproperties,'MaxMinTable'));
            mytables = {'MaxMinTable'};
            myfiles = {};
            
            myattributes.properties = myproperties;
            myattributes.tables = mytables;
            myattributes.files = myfiles;
        end
    end
    
    properties
        Header
        MaxMinTable
        comments
    end
end

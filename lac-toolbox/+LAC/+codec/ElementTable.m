classdef ElementTable
    methods (Static)
        function output = decode(VTSCoder, tableType)
            output = struct();
            
            %[tableType, output.header, nRows, nColumns] = LAC.vts.shared.ElementTable.detectTableType(VTSCoder);
            switch tableType
                case 1
                    % mass  cgx	  cgy  cgz	J2x0     J2y0	 J2z0
                    % 70000 0.63  0    0.0  2.75E4   2.75E5  2.75E5
                    % -1
                    
                    output.columnnames = strsplit_LMT(output.header{1});
                    startline = VTSCoder.current();
                    rawdata = VTSCoder.lines(startline,startline+nRows);
                    output.data = cell(nRows,nColumns);
                    for i = 1:nRows
                        tmp = textscan(rawdata{i}, '%s');
                        if length(tmp{1}) < nColumns
                            nColumns = length(tmp{1});
                            output.data(i,:) = tmp{1};
                        else
                            output.data(i,:) = {tmp{1}{1:nColumns-1} strjoin_LMT(tmp{1}(nColumns:end)')};
                        end
                    end
                    
                    VTSCoder.skip(1); % Skip line with '-1'
                    
                case 2
                    % 12                           no of shaft sections
                    % -2873   570  110     0          x   Dout Din  Radius  [mm]
                    % -2543   570  110     0          Radius<1 : position of main bearing
                    % -2000   520  110     0
                    % -620    680  110     0
                    % -512    708  110     0
                    % -337    708  110     0
                    % -327    710  110     0
                    % -258    710  110    -1          fixes main bearing position
                    %    0    710  110   270
                    %  324   1250  110     0
                    %  325   1490  110     0
                    %  484   1490  110     0
                    nRows = str2num(VTSCoder.get());
                    nColumns = 4;
                    startline = VTSCoder.current();
                    if isnan(nRows)
                        % Number of row not specified, try to detect
                        tmpcolumns = nColumns;
                        nRows = -1;
                        while nColumns == tmpcolumns
                            nRows=nRows+1;
                            tmp = VTSCoder.lines(startline+nRows,startline+nRows);
                            tmp2 = textscan(tmp{1}, '%f');
                            tmpcolumns = length(tmp2{1});
                        end
                    end
                    rawdata = VTSCoder.lines(startline,startline+nRows-1);
                    
                    output.data = cell(nRows,nColumns);
                    output.comments = cell(nRows,1);
                    for i = 1:nRows
                        tmp = textscan(rawdata{i}, '%s');
                        if length(tmp{1}) <= nColumns
                            nColumns = length(tmp{1});
                            output.data(i,:) = tmp{1};
                            output.comments{i} = '';
                        else
                            output.data(i,:) = tmp{1}(1:nColumns);
                            output.comments{i} = strjoin_LMT(tmp{1}(nColumns+1:end)');
                        end                        
                    end
                    VTSCoder.skip(nRows)
                case 3
                    % 3 17  nrow ncoloum (control voltage [V]-pitch moment [kNm]-pitch rate [deg/s] table for normal production)
                    %         -100  -80     -70     -60     -50     -40     -30     -20     -10     0       10      20      30      40      50      60      100
                    % -10.0	  88.15	11.38	-6.65	-9.55	-11.78	-13.66	-15.32	-16.82	-18.20	-19.48	-20.69	-21.83	-22.91	-23.95	-24.94	-25.90	-29.42
                    % -9.0	  88.15	11.38	-6.47	-9.26	-11.42	-13.24	-14.85	-16.30	-17.63	-18.87	-20.04	-21.15	-22.19	-23.20	-24.16	-25.09	-28.50
                    % -8.0	  88.15	11.38	-6.15	-8.78	-10.82	-12.55	-14.07	-15.44	-16.75	-17.88	-18.98	-20.02	-21.02	-21.97	-22.88	-23.75	-26.99
                    [nRows, nColumns] = VTSCoder.get();
                    nRows    = str2num(nRows);
                    nColumns = str2num(nColumns);
                    
                    [tmp] = VTSCoder.get(true);
                    tmp = strsplit_LMT(tmp);
                    output.columnnames = tmp(2:end);
                    output.columnnames = output.columnnames(~isnan(str2double(output.columnnames))); % Remove comment text
                    
                    output.rownames = cell(nRows,1);
                    output.data = cell(nRows,nColumns);
                    startline = VTSCoder.current();
                    rawdata = VTSCoder.lines(startline,startline+nRows-1);
                    for i = 1: nRows
                        tmp = textscan(rawdata{i}, '%s');
                        output.rownames{i} = tmp{1}{1};
                        output.data(i,:) = tmp{1}(2:end);
                    end
                    VTSCoder.skip(nRows)
                case 4
                    % 4              No of blade cross section
                    % ------------------------------------------------------------------------------------------------------------------------------
                    % R       EI-Flap    EI-Edge      GIp    	    m     J   Xcog     Xshc     UF0    UE0    C      t/C      beta     Yac/C   PhiOut   Out
                    % ------------------------------------------------------------------------------------------------------------------------------
                    % 1       7.12E+09   7.12E+09   0.00E+00   947.3   0.00  0.0050   0.0260   0.000  0.000  1.88   100.00    0       -0.250    0       6.123
                    % 1.01    7.12E+09   7.12E+09   0.00E+00   947.3   0.00  0.0050   0.0268   0.000  0.000  1.88   100.00    24.1    -0.250    24.1    6.123
                    % 2       4.79E+09   4.79E+09   0.00E+00   649.0   0.00  0.0090   0.1040   0.000  0.000  1.84   100.00    24.1    -0.250    24.1    0 AOA Cl Cd
                    % 4       2.15E+09   2.38E+09   0.00E+00   428.3   0.00  0.0350   0.0830   0.000  0.000  2.45   66.351    23.4    -0.159    23.4    0
                    
                    output.columnnames = strsplit_LMT(output.header{1});
                    
                    startline = VTSCoder.current();
                    rawdata = VTSCoder.lines(startline,startline+nRows-1);
                    output.data = cell(nRows,nColumns);
                    output.comments = cell(nRows,1);
                    for i = 1:nRows
                        tmp = textscan(rawdata{i}, '%s');
                        if length(tmp{1}) < nColumns
                            nColumns = length(tmp{1});
                            output.data(i,:) = tmp{1};
                            output.comments{i} = '';
                        else
                            output.data(i,:) = tmp{1}(1:nColumns);
                            output.comments{i} = strjoin_LMT(tmp{1}(nColumns+1:end)');
                        end
                    end
                    
                case 6
                    % 4              No of blade cross section
                    % ------------------------------------------------------------------------------------------------------------------------------
                    % R       EI-Flap    EI-Edge      GIp    	    m     J   Xcog     Xshc     UF0    UE0    C      t/C      beta     Yac/C   PhiOut   Out
                    % ------------------------------------------------------------------------------------------------------------------------------
                    % 1       7.12E+09   7.12E+09   0.00E+00   947.3   0.00  0.0050   0.0260   0.000  0.000  1.88   100.00    0       -0.250    0       6.123
                    % 1.01    7.12E+09   7.12E+09   0.00E+00   947.3   0.00  0.0050   0.0268   0.000  0.000  1.88   100.00    24.1    -0.250    24.1    6.123
                    % 2       4.79E+09   4.79E+09   0.00E+00   649.0   0.00  0.0090   0.1040   0.000  0.000  1.84   100.00    24.1    -0.250    24.1    0 AOA Cl Cd
                    % 4       2.15E+09   2.38E+09   0.00E+00   428.3   0.00  0.0350   0.0830   0.000  0.000  2.45   66.351    23.4    -0.159    23.4    0
                    
                    % Get number of rows and columns
                    currentline = VTSCoder.current();
                    rawdata = VTSCoder.lines(currentline,currentline+4);
                    VTSCoder.skip(4);
                    nRows = regexp(rawdata{1},'\s*(\d+)\s+.*','Tokens');
                    nRows = nRows{1};
                    colNames=textscan(rawdata{3}, '%s'); % Assumes that the header is correct!
                    nColumns = num2str(length(colNames{1}));
                    
                    thisclass = feval(mfilename('class'));
                    output = thisclass.readTable(VTSCoder, nRows, nColumns);
                    %output.columnnames = {'Radius','EIflap','EIedge','GIp','m','J','ycog','yshc','uf0','ue0','Chord','Thickness','Beta','YaCC','PhiOut','POut'};
                    output.columnnames=colNames{1};
                    output.header = strjoin_LMT(rawdata(2:4)','\n');
                   
                case 7
                    % Efficiency tables.
                    % 3 17  nrow ncoloum (control voltage [V]-pitch moment [kNm]-pitch rate [deg/s] table for normal production)
                    %         -100  -80     -70     -60     -50     -40     -30     -20     -10     0       10      20      30      40      50      60      100
                    % -10.0	  88.15	11.38	-6.65	-9.55	-11.78	-13.66	-15.32	-16.82	-18.20	-19.48	-20.69	-21.83	-22.91	-23.95	-24.94	-25.90	-29.42
                    % -9.0	  88.15	11.38	-6.47	-9.26	-11.42	-13.24	-14.85	-16.30	-17.63	-18.87	-20.04	-21.15	-22.19	-23.20	-24.16	-25.09	-28.50
                    % -8.0	  88.15	11.38	-6.15	-8.78	-10.82	-12.55	-14.07	-15.44	-16.75	-17.88	-18.98	-20.02	-21.02	-21.97	-22.88	-23.75	-26.99
                    
                    % Read header.
                    [output.header{1}] = VTSCoder.get(true);
                    
                    % Read number of rows and columns.
                    [nRows, nColumns] = VTSCoder.get(true);
                    nRows = str2double(nRows);
                    nColumns = str2double(nColumns);
                    
                    % Read column "header data" ("power", in case of an efficiency table).
                    [line] = VTSCoder.get(true);
                    data = textscan(line,'%s');
                    output.columnnames = data{1}'; % Seems that we need to use "'" in order to be consistent with the "encode" function for tables.
                    
                    % Parse table data.
                    output.data = cell(nRows,nColumns);
                    startline = VTSCoder.current();
                    rawdata = VTSCoder.lines(startline,startline+nRows-1);
                    for irow=1:nRows
                        % Set current line.
                        result = textscan(rawdata{irow}, '%f');
                        line = result{1};
                        for icolumn=1:length(line)
                            if icolumn==1
                                % First column goes into separate variable.
                                output.rownames{irow} = line(icolumn);
                            else
                                % Use -1 since the first column is == "row_names".
                                output.data{irow,icolumn-1} = line(icolumn);
                            end
                        end
                    end
                    
                    % Skip ahead in the VTSCoder.
                    VTSCoder.skip(nRows)
                    
                otherwise
                    error('Unsupported table type')
            end
            
            if isfield(output, 'comments')
                if cellfun('isempty', output.comments)
                    output = rmfield(output,'comments');
                end
            end
            
            if isfield(output, 'columnnames')
                if isnan(sum(str2double(output.columnnames)))
                    output.datastruct = cell2struct(output.data, regexprep(output.columnnames,'[''/-\(\)]',''), 2);
                end
            end
            
            %VTSCoder.skip(nRows);
        end
        
%         function [tabletype, tableheader, nRows, nColumns] = detectTableType(VTSCoder)
%             % Detect type from raw text
%             
%             tabletype = 0;
%             tableheader = {VTSCoder.get(true)};
%             nRows = NaN;
%             nColumns = NaN;
%             
%             tmp = strsplit_LMT(tableheader{1});
%             if length(tmp) > 0
%                 nRows = str2double(tmp{1});
%                 if ~isnan(nRows)
%                     if ~isempty(regexpi(tmp{1},'[\-\.a-z]')) % Is float
%                         % No header on table
%                         nRows = NaN;
%                         VTSCoder.skip(-1);
%                         tableheader{1} = '';
%                     end
%                     startline = VTSCoder.current();
%                     rawdata = VTSCoder.lines(startline,startline);
%                     
%                     tabletype = 2;
%                     if length(rawdata{1}) > 38
%                         if strcmpi(rawdata{1}(1:38),'--------------------------------------')
%                             rawdata = VTSCoder.lines(startline,startline+4);
%                             VTSCoder.skip(3);
%                             %tableheader = rawdata(1:3);
%                             tableheader = rawdata(2);
%                             rawdata = rawdata(4:end);
%                             tabletype = 4;
%                         end
%                     end
%                     if ~isempty(strfind(rawdata{1}, ','))
%                         rawdata = VTSCoder.lines(startline,startline+2);
%                         VTSCoder.skip(1);
%                         tableheader = rawdata(1);
%                         rawdata = rawdata(2:end);
%                         tabletype = 4;
%                     end
%                     nColumns = textscan(rawdata{1}, '%f');
%                     nColumns = length(nColumns{1});
%                 end
%             end
%             if length(tmp) > 1
%                 if isempty(regexpi(tmp{2},'[\-\.a-z]')) % is integer
%                     nColumns = str2double(tmp{2});
%                     tabletype = 3;
%                 end
%             end
%             
%             if isnan(nRows) && isnan(nColumns)
%                 startline = VTSCoder.current();
%                 VTSCoder.search('^-1[\s+]?$');
%                 endline = VTSCoder.current();
%                 if startline ~= endline
%                     VTSCoder.skip(startline-endline);
%                     tabletype = 1;
%                     nColumns = length(strsplit_LMT(tableheader{1}));
%                     nRows = endline-startline;
%                 end
%             end
%             
%             if isnan(nRows) && isnan(nColumns)
%                 line2 = VTSCoder.get(true);
%                 tmp = textscan(line2, '%f');
%                 if length(tmp{1})==2
%                     tabletype = 3;
%                     nRows = tmp{1}(1);
%                     nColumns = tmp{1}(2);
%                 end
%             end
%         end
        
        
        function output = readTable(VTSCoder, rows, columns)
            startline = VTSCoder.current();
            
            % TBD: Need to handle text in matrix!!
            
            output.data = cell(rows,columns);
            output.comments = cell(rows,1);
            rawdata = VTSCoder.lines(startline,startline+rows-1);
            for i = 1:length(rawdata)
                tmp = textscan(rawdata{i}, '%s');
                if length(tmp{1}) <= columns
                    columns = length(tmp{1});
                    output.data(i,:) = tmp{1};
                    output.comments{i} = '';
                else
                    output.data(i,:) = tmp{1}(1:columns);
                    output.comments{i} = strjoin_LMT(tmp{1}(columns+1:end)',' ');
                end
            end
            
            if all(cell2mat(cellfun(@(x) isempty(x), output.comments, 'UniformOutput', false)))
                output = rmfield(output,'comments');
            end
            %output.data = cellfun(@(x) str2double(x), output.data, 'UniformOutput', false);
            VTSCoder.skip(rows);
        end
        
        function writeTable(VTSCoder, mydata, strformat)
            function x = formatnumber(x)
                if ~(abs(round(x)-x) <= eps('double'))
                    x = num2str(x,strformat);
                else
                    x = num2str(x);
                end
            end
            tmp = cellfun(@(x) formatnumber(x), mydata.data, 'UniformOutput', false);
            LAC.codec.ElementTable.writetable(VTSCoder, tmp, isfield(mydata,'comments'));
        end
        
        function status = encode(VTSCoder, inputdata, tableType)
%             type = 0;
%             
%             % Detect type from struct
%             if length(inputdata.header) == 3
%                 type = 6;
%             else
%                 tmp = strsplit_LMT(char(inputdata.header));
%                 nRows = NaN;
%                 nColumns = NaN;
%                 if length(tmp) > 0
%                     nRows = str2double(tmp{1});
%                 end
%                 if length(tmp) > 1
%                     nColumns = str2double(tmp{2});
%                 end
% 
%                 if ~isnan(nRows)
%                     type = 4;
%                 else
%                     type = 5;
%                 end
%                 if isfield(inputdata, 'rownames')
%                     if ~isnan(nRows) && ~isnan(nColumns)
%                         type = 2;
%                     else
%                         type = 1;
%                     end
%                 end
%                 if isfield(inputdata, 'comments')
%                     type = 3;
%                 end
%             end
            
            switch tableType
                case 1
                    % Case 1:
                    % G1 Mechanical efficiency table (power[kW]-RPM-efficiency)
                    % 15 23
                    %       25      50      100     150     200	300	400	500	600	700	800	900	1000	1100	1200	1300	1400	1500	1600	1800	2000	2200	2400
                    % 850	0.500	0.526	0.758	0.835	0.873	0.910	0.927	0.936	0.942	0.945	0.947	0.948	0.948	0.948	0.947	0.946	0.944	0.943	0.941	0.938	0.936	0.930	0.923
                    % 950	0.500	0.518	0.756	0.834	0.873	0.911	0.929	0.939	0.946	0.950	0.952	0.954	0.955	0.955	0.955	0.955	0.954	0.954	0.953	0.951	0.950	0.946	0.942
                    
                    VTSCoder.setLine(inputdata.header{1})
                    
                    [nRows,nColumns] = size(inputdata.data);
                    % The reader cannot handle "Rows Columns". Dont write them to the file!
                    %VTSCoder.setLine([sprintf('%-32s', deblank(sprintf('%d ', [nRows,nColumns]))) 'Rows Columns']);
                    VTSCoder.setLine([sprintf('%-32s', deblank(sprintf('%d ', [nRows,nColumns])))]);
                    
                    tmp = [inputdata.rownames' inputdata.data];
                    tmp = [{''} inputdata.columnnames; tmp];
                    if false
                        % Seems that some code is missing?? LAC.vts.shared.ElementTable.writetable??
                        LAC.vts.shared.ElementTable.writetable(VTSCoder, tmp, false);
                    else                        
                        % Write data.
                        tab = char(9);
                        line = tab; % Start with tab.
                        for icolumn=1:length(inputdata.columnnames)
                            line = [line sprintf('%s', inputdata.columnnames{icolumn}) tab];
                        end
                        VTSCoder.setLine(line);
                        
                        % Write remaining part of header.
                        for irow=1:length(inputdata.rownames)
                            line = sprintf('%.0f', inputdata.rownames{irow});
                            line = [line tab];
                            for icolumn=1:size(inputdata.data,2)
                                % Flag.
                                is_last_column = icolumn == size(inputdata.data,2);
                                if is_last_column
                                    % Dont use tab.
                                    line = [line sprintf('%.3f', inputdata.data{irow, icolumn})];
                                else
                                    line = [line sprintf('%.3f', inputdata.data{irow, icolumn}) tab];
                                end
                            end
                            VTSCoder.setLine(line);
                        end
                        
                    end
                    
                case 2
                    % Case 2:
                    % 3 17  nrow ncoloum (control voltage [V]-pitch moment [kNm]-pitch rate [deg/s] table for normal production)
                    %          -100   -80     -70     -60     -50     -40     -30     -20     -10     0       10      20      30      40      50      60      100
                    % -10.0	  88.15	11.38   -6.65	-9.55	-11.78	-13.66	-15.32	-16.82	-18.20	-19.48	-20.69	-21.83	-22.91	-23.95	-24.94	-25.90	-29.42
                    % -9.0	  88.15	11.38	-6.47	-9.26	-11.42	-13.24	-14.85	-16.30	-17.63	-18.87	-20.04	-21.15	-22.19	-23.20	-24.16	-25.09	-28.50
                    % -8.0	  88.15	11.38	-6.15	-8.78	-10.82	-12.55	-14.07	-15.44	-16.75	-17.88	-18.98	-20.02	-21.02	-21.97	-22.88	-23.75	-26.99
                    
                    [actualRows,actualColumns] = size(inputdata.data);
                    inputdata.header{1} = strrep(inputdata.header{1}, num2str(nRows), num2str(actualRows));
                    inputdata.header{1} = strrep(inputdata.header{1}, num2str(nColumns), num2str(actualColumns));
                    VTSCoder.setLine(inputdata.header{1})
                    tmp = [inputdata.rownames inputdata.data];
                    tmp = [{''} inputdata.columnnames; tmp];                    
                    LAC.vts.shared.ElementTable.writetable(VTSCoder, tmp, false);
                    
                case 3
                    % Case 3:
                    % 12                           no of shaft sections
                    % -2873   570  110     0          x   Dout Din  Radius  [mm]
                    % -2543   570  110     0          Radius<1 : position of main bearing
                    % -2000   520  110     0
                    % -620    680  110     0
                    % -512    708  110     0
                    % -337    708  110     0
                    % -327    710  110     0
                    % -258    710  110    -1          fixes main bearing position
                    %    0    710  110   270
                    %  324   1250  110     0
                    %  325   1490  110     0
                    %  484   1490  110     0
                    
                    [actualRows,~] = size(inputdata.data);
                    VTSCoder.setLine(num2str(actualRows))
%                     if ~isempty(inputdata.header{1})
%                         inputdata.header{1} = strrep(inputdata.header{1}, num2str(nRows), num2str(actualRows));
%                         VTSCoder.setLine(inputdata.header{1})
%                     end
                    if isfield(inputdata, 'comments')
                        tmp = [inputdata.data inputdata.comments];
                        comments = true;
                    else
                        tmp = inputdata.data;
                        comments = false;
                    end
                    LAC.codec.ElementTable.writetable(VTSCoder, tmp, false);
                    
                case 4
                    % 7    H	D	    t 	    M	    Cd      Out
                    % 58.300	2.316	0.016	1621	0.65	6.1
                    % 58.050	2.316	0.016	0       0.65	0
                    % 57.930	2.316	0.016	0       0.65	0
                    % 55.250	2.562	0.012	0       0.65	0
                    % 53.250	2.603	0.012	0       0.65	0
                    % 51.260	2.644	0.012	0       0.65	2.1
                    % 48.400	2.703	0.013	0       0.65	0
                    
                    [actualRows,~] = size(inputdata.data);
                    inputdata.header{1} = strrep(inputdata.header{1}, num2str(nRows), num2str(actualRows));
                    VTSCoder.setLine(inputdata.header{1})
                    LAC.vts.shared.ElementTable.writetable(VTSCoder, inputdata.data, false);
                    
                case 5
                    % mass  cgx	  cgy  cgz	J2x0     J2y0	 J2z0
                    % 70000 0.63  0    0.0  2.75E4   2.75E5  2.75E5
                    % -1
                    
                    VTSCoder.setLine(inputdata.header{1})
                    LAC.vts.shared.ElementTable.writetable(VTSCoder, inputdata.data, false);
                    VTSCoder.setLine('-1')
                    
                case 6
                    % 4              No of blade cross section
                    % ------------------------------------------------------------------------------------------------------------------------------
                    % R       EI-Flap    EI-Edge      GIp    	    m     J   Xcog     Xshc     UF0    UE0    C      t/C      beta     Yac/C   PhiOut   Out
                    % ------------------------------------------------------------------------------------------------------------------------------
                    % 1       7.12E+09   7.12E+09   0.00E+00   947.3   0.00  0.0050   0.0260   0.000  0.000  1.88   100.00    0       -0.250    0       6.123
                    % 1.01    7.12E+09   7.12E+09   0.00E+00   947.3   0.00  0.0050   0.0268   0.000  0.000  1.88   100.00    24.1    -0.250    24.1    6.123
                    % 2       4.79E+09   4.79E+09   0.00E+00   649.0   0.00  0.0090   0.1040   0.000  0.000  1.84   100.00    24.1    -0.250    24.1    0 AOA Cl Cd
                    % 4       2.15E+09   2.38E+09   0.00E+00   428.3   0.00  0.0350   0.0830   0.000  0.000  2.45   66.351    23.4    -0.159    23.4    0
                    
                    VTSCoder.setLine([sprintf('%-28s', num2str(size(inputdata.data,1))) 'No of blade cross section']);
                    for i=1:length(inputdata.header)
                        VTSCoder.setLine(inputdata.header{i})
                    end
                    if isfield(inputdata, 'comments')
                        tmp = [inputdata.data inputdata.comments];
                    else
                        tmp = inputdata.data;
                    end
                    LAC.vts.shared.ElementTable.writetable(VTSCoder,tmp, true);
                    
                otherwise
                    error('Unsupported table type')
            end
            
            status = tableType~=0;
        end
        
        function writetable(VTSCoder, mydata, commentsIncluded)
            [nRows,nColumns] = size(mydata);
            %columnWidths = regexpi(inputdata.header,'[\w]+');
            maxcolumnwidth = max(max(cellfun(@(x) length(x), mydata,'uni',true)));
            columnWidths = 1:maxcolumnwidth:nColumns*maxcolumnwidth;
            myline = cell(1,nColumns);
            for j=1:nColumns
                if j==1
                    maxlength = cellfun(@(x) length(x), mydata(:,j),'uni',false);
                    maxlength = max([maxlength{:}]);
                    myline{:,j} = strsplit_LMT(sprintf(['%-' num2str(maxlength) 's,'], mydata{:,j}),',');
%                     myline{:,j}(end) = [];
                elseif j==nColumns
                    if commentsIncluded
                        myline{:,j} = strsplit_LMT(sprintf('     %s,', mydata{:,j}),',');
%                         myline{:,j}(end) = [];
                    else
                        myline{:,j} = strsplit_LMT(sprintf(['%' num2str(maxcolumnwidth) 's,'], mydata{:,j}),',');
%                         myline{:,j}(end) = [];
                    end
                else
                    myline{:,j} = strsplit_LMT(sprintf(['%' num2str(columnWidths(j)-columnWidths(j-1)) 's,'], mydata{:,j}),',');
%                     myline{:,j}(end) = [];
                end
            end
            
            % Rearrange matrix
            tmp = {};
            for i = 1:length(myline)
                tmp = [tmp; myline{i}];
            end
            for i=1:nRows
                VTSCoder.setLine(strjoin_LMT(tmp(:,i)'));
            end
        end
    end
    
end
function [Table, X_1st_Column, varargout] = ReadAero3dLookUp(Filename, TableName, varargin)
% Input: 
%   Filename     [mandatory] - File containing desired tables.
%   TableName - Name of the table to be loaded
%
%   List of names:
%
%   matrices: 
%   1.) 'AoA-mat' - Angle of attack 
%   2.) 'CL-mat'  - Coefficient of lift
%   3.) 'CD-mat'  - Coefficient of drag
%   4.) 'CM-mat'  - Coefficient of mass
%   5.) 'CP-mat'  - Coefficient of power
%   6.) 'CT-mat'  - Coefficient of thrust
%   7.) 'A1-mat'  - a 
%   8.) 'A2-mat'  - a' 
%   9.) 'V-mat'   - velocity 
%   tables:
%   1.) 'CP-tab'  - Coefficient of power
%   2.) 'AoA-tab' - Angle of attack 
%   3.) 'VRel-table under' - relative velocity
%
%   NumOfColumns [optional] - Number of columns of the table table. If
%   provided, then the function does not have to find out the number of
%   columns of the table.
%   
% Output: 
%   Table           - Table w.r.t. X and Y axes.
%   X_1st_Column    - X axis of the table given by the first row.
%   Y_1st_Row       - Y axis of the table given by the first row.

if ~isempty(varargin)
    EndCol = varargin{1};
else
    EndCol = NaN;
end

if nargout > 2
    Y_1st_Row_needed = true;
else
    Y_1st_Row_needed = false;
end

Table = NaN;
X_1st_Column = NaN;
Y_1st_Row = NaN;

% Get search string associated to the table name:
[TableRegExp, SearchByName] = getSearchString(TableName);

Fid=fopen(Filename);
StartLine = NaN;
EndLine = NaN;
nline=0;  % changes to sort out error that it did not extract the entire table

while ~feof(Fid)
    tline = fgetl(Fid);
    nline = nline+1;
    
    % Detect start line of the table:
    if regexp(tline, TableRegExp, 'once')
        if SearchByName == true
            StartLine = nline+1;
        else
            StartLine = nline;
        end
        
        % Reading AEP - AEP can be extracted directly
        if strcmp(TableName,'AEP')
            Table=str2double(regexp(tline,'([+-]?[\d\.\-]+)','match'));
            break
        end
        
        if strcmp(TableName,'cpaeromax') % optimal CP can be extracted directly
            Table=str2double(regexp(tline,'\s([+-]?[\d\.\-]+)','match'));
            break
        end
        
        if strcmp(TableName,'TSRopt')  % optimal TSR can be extracted directly
            Table=str2double(regexp(tline,'\s([+-]?[\d\.\-]+)','match'));
            break
        end
        
        if strcmp(TableName,'Phiopt')  % optimal pitch can be extracted directly
            Table=str2double(regexp(tline,'\s([+-]?[\d\.\-]+)\s','match'));
            break
        end        
            
        % If the size of table is unknown or values of Y-axis are required:
        if ( (isempty(EndCol) || isnan(EndCol)) || (Y_1st_Row_needed == true) )
            % Copy theta values from the first row of the table:
            tline = fgetl(Fid);
            nline = nline + 1;
            Theta_cell=regexp(tline,'([+-]?[\d\.\-]+)','match');
            EndCol = length(Theta_cell);
            Y_1st_Row = zeros(1,EndCol);
            for n=1:EndCol
                Y_1st_Row(1,n)=str2double(Theta_cell{1,n});
            end
        end
        
    end
    
        % this piece of code is to make the code compliant with the latest
        % version of pyro. In that version, the units are added as a new
        % line. Those lines should be ommitted. These lines currently seem
        % to contain the string 'm/s' consistently.
        % Detect if a line contains 'm/s' - if it does, StartLine should be the next one :
        if ~isnan(StartLine) && (contains(tline, 'm/s') || contains(tline, 'lambda'))
            % disp(TableName)  % used for DEBUGGING
            % disp(tline)      % used for DEBUGGING
            % disp(nline)      % used for DEBUGGING
            StartLine = nline + 1;
        end    
    
    
    % Detect last line of the table:
    if ~isnan(StartLine) && isempty(tline)
        EndLine = nline;
        break
    end
end

% disp([num2str(StartLine) ' - ' num2str(EndLine)])  % DEBUG

fclose(Fid);

% Read the table from the start line to the end line:
if ~(isnan(StartLine)||isnan(EndLine))
    StartRow = StartLine -1 ;
    EndRow = EndLine-2;
    % fprintf([TableName ' ' num2str(StartLine) ' 0 - ' num2str(EndLine) ' ' num2str(EndCol) ': ' ])  % used for DEBUGGING
    Table = dlmread(Filename,'',[StartRow 0 EndRow EndCol]);
    %fprintf([num2str(Table(1,1)) ' ' num2str(Table(size(Table, 1),size(Table, 2))) '\n'])  % used for DEBUGGING
    X_1st_Column = Table(:,1);  % not changed
    Table = Table(:,2:end);     % not changed
else
    warning('ReadAero3dLookUp:TableNotFound',' Table given by the regular expression %s was not found in the file %s!', TableRegExp, Filename);
end

if nargout >= 3
    varargout{1} = Y_1st_Row;
end
if nargout >= 4
    varargout{2} = EndCol;
end    

end

function [TableRegExp, SearchByName] = getSearchString(TableName)
% INPUTS:
%   TableName - Name of the table to be loaded
%
%   List of names:
%
%   matrices: 
%   1.) 'AoA-mat' - Angle of attack 
%   2.) 'CL-mat'  - Coefficient of lift
%   3.) 'CD-mat'  - Coefficient of drag
%   4.) 'CM-mat'  - Coefficient of mass
%   5.) 'CP-mat'  - Coefficient of power
%   6.) 'CT-mat'  - Coefficient of thrust
%   7.) 'A1-mat'  - a 
%   8.) 'A2-mat'  - a' 
%   9.) 'V-mat'   - velocity 
%   tables:
%   1.) 'CP-tab'  - Coefficient of power
%   2.) 'AoA-tab' - Angle of attack 
%   3.) 'VRel-table under' - relative velocity
%
%   OUTPUTS:
%   TableRegExp - gular expression used to locate the table in the file
%
%   SearchByName - if true, table is anotatted using table name and axes
%   name. If false, table is anotated only using axes name. This flag
%   indicates how to search for the table in the file. 
%   If set to true, table in the file should have a name, e.g. 'CP-table'. 
%   If set to false, table doesn't have a name and then the search is
%   performed using axes name, e.g. 'CP'.
%   Example of table with name (where the name of the table is CP-table and
%   the axes name is lambda\theta): 
%   CP-table
%   lambda\theta      -5.00      -4.80  
%           0.80  -0.002009  -0.001922  
%           1.00  -0.002535  -0.002413
%   Example of table without name (Table name is missing, but the table can
%   be found by the axes name - 'CP'): 
%   CP        3.0m/s   3.5m/s   
%     1.350  -0.0220  -0.0160  
%     2.650  -0.0476  -0.0340  
%     4.000  -0.0665  -0.0499 


% PESEG - 201212 - changed all the RegExp strings to be inline with the
% latest pyro format, and also to be backward compatible. Tested up to old
% aero files with Danish naming.
TableRegExp = NaN; % regular expression used for locating the table in the file 
SearchByName = NaN; % If the table has a name in the file, or if ust the name of the axes is used.

switch TableName
    case 'AoA-mat'
        %TableRegExp = '(AoA|Alpha|alfa)\s+.*m/s';
        TableRegExp = '^\s*(AoA|Alpha|alfa)\s+';
        SearchByName = false;
    case 'CL-mat'
        %TableRegExp = '(CL|cl)\s+.*m/s';
        TableRegExp = '^\s*(CL|cl)\s+';
        SearchByName = false;
    case 'CD-mat'
        %TableRegExp = '(CD|cd)\s+.*m/s';
        TableRegExp = '^\s*(CD|cd)\s+';
        SearchByName = false;
    case 'CM-mat'
        %TableRegExp = '(CM|cm) \s+.*m/s';
        TableRegExp = '^\s*(CM|cm)\s+';
        SearchByName = false;
    case 'CP-mat'
        %TableRegExp = '(CP|cp)\s+.*m/s';
        TableRegExp = '^\s*(CP|cp)\s+';
        SearchByName = false;
    case 'CT-mat'
        %TableRegExp = '(CT|ct)\s+.*m/s';
        TableRegExp = '^\s*(CT|ct)\s+';
        SearchByName = false;
    case 'A1-mat'
        %TableRegExp = '^(\s*a) \s+.*m/s';
        TableRegExp = '^(\s*a)\s+';
        SearchByName = false;
    case 'A2-mat'
        %TableRegExp = '^(\s*a'') \s+.*m/s';
        TableRegExp = '^(\s*a'')\s+';
        SearchByName = false;
    case 'V-mat'
        %TableRegExp = '^(\s*v) \s+.*m/s';
        TableRegExp = '^\s*(v)\s+';
        SearchByName = false;
    case 'CP-tab'
        TableRegExp = 'CP-(table|tabel)';
        SearchByName = true;
    case 'CT-tab'
        TableRegExp = 'CT-(table|tabel)';
        SearchByName = true;
    case 'AoA-tab'
        TableRegExp = 'AoA-table';
        SearchByName = true;
    case 'VRel-table under'
        TableRegExp = 'Vrel-table';
        SearchByName = true;
    case 'AEP'
        TableRegExp = '^\s*(AEP|Aarsproduktion)\s+';
        SearchByName = false;      
    case 'cpaeromax'
        TableRegExp = '^(CPmax|CPmax:)\s+';
        SearchByName = false;  
    case 'Phiopt'
        TableRegExp = '^(Optimal pitch_setting|Optimal pitchvinkel|Optimum pitch angle:)\s+';
        SearchByName = false;  
    case 'TSRopt'
        TableRegExp = '^(Optimal tip_speed_ratio|Optimalt tiphastighedsforhold|Optimum tip speed ratio:)\s+';
        SearchByName = false;  
        
end

end
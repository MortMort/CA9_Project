function [] = TurnerGearExtremeLoadsMatrix_AllAzim(DataMaxBin,DataMinBin,varargin)
    % Parse input.
    Parser = inputParser;
    Parser.addOptional('OutputFolder',cd);

    % Parse.
    Parser.parse(varargin{:});

    % Set variables.
    OutputFolder = Parser.Results.('OutputFolder');

    % Blade 1 only, and Blades 1&2 only %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    GearRatio = 1; % LSS load!

    Yaw     = round(DataMaxBin(:,1)/5)*5;
    Azim    = round(DataMinBin(:,2)/5)*5;

    % Extreme values (no filtering)
    Max1B_positive = max(DataMaxBin(:,3:5),[],2);
    Min1B_negative = min(DataMinBin(:,3:5),[],2);
    Max2B_positive = max(DataMaxBin(:,6:8),[],2);
    Min2B_negative = min(DataMinBin(:,6:8),[],2);

    Max1B = max(Max1B_positive,abs(Min1B_negative));
    Max2B = max(Max2B_positive,abs(Min2B_negative));

    % Extreme values, 2s filtering
    Max1B_2sf_positive = max(DataMaxBin(:,10:12),[],2);
    Min1B_2sf_negative = min(DataMinBin(:,10:12),[],2);
    Max2B_2sf_positive = max(DataMaxBin(:,13:15),[],2);
    Min2B_2sf_negative = min(DataMinBin(:,13:15),[],2);

    Max1B_2sf = max(Max1B_2sf_positive,abs(Min1B_2sf_negative));
    Max2B_2sf = max(Max2B_2sf_positive,abs(Min2B_2sf_negative));

    % Extreme values, 60s filtering
    Max1B_60sf_positive = max(DataMaxBin(:,17:19),[],2);
    Min1B_60sf_negative = min(DataMinBin(:,17:19),[],2);
    Max2B_60sf_positive = max(DataMaxBin(:,20:22),[],2);
    Min2B_60sf_negative = min(DataMinBin(:,20:22),[],2);

    Max1B_60sf = max(Max1B_60sf_positive,abs(Min1B_60sf_negative));
    Max2B_60sf = max(Max2B_60sf_positive,abs(Min2B_60sf_negative));

    % Extreme values, peak to peak
    Max1B_pp = DataMaxBin(:,25:27);
    Max2B_pp = DataMaxBin(:,28:30);

    Array.Yaw = unique(Yaw);
    Array.Azim = unique(Azim);
    Array.Max1B = zeros(length(Array.Yaw),length(Array.Azim));
    Array.Max2B = zeros(length(Array.Yaw),length(Array.Azim));
    Array.Max1B_2sf = zeros(length(Array.Yaw),length(Array.Azim));
    Array.Max2B_2sf = zeros(length(Array.Yaw),length(Array.Azim));
    Array.Max1B_60f = zeros(length(Array.Yaw),length(Array.Azim));
    Array.Max2B_60f = zeros(length(Array.Yaw),length(Array.Azim));
    Array.Max1B_pp = zeros(length(Array.Yaw),length(Array.Azim));
    Array.Max2B_pp = zeros(length(Array.Yaw),length(Array.Azim));

    Array.Max1B_positive = zeros(length(Array.Yaw),length(Array.Azim));
    Array.Min1B_negative = zeros(length(Array.Yaw),length(Array.Azim));
    Array.Max2B_positive = zeros(length(Array.Yaw),length(Array.Azim));
    Array.Min2B_negative = zeros(length(Array.Yaw),length(Array.Azim));

    Array.Max1B_2sf_positive = zeros(length(Array.Yaw),length(Array.Azim));
    Array.Min1B_2sf_negative = zeros(length(Array.Yaw),length(Array.Azim));
    Array.Max2B_2sf_positive = zeros(length(Array.Yaw),length(Array.Azim));
    Array.Min2B_2sf_negative = zeros(length(Array.Yaw),length(Array.Azim));

    Array.Max1B_60sf_positive = zeros(length(Array.Yaw),length(Array.Azim));
    Array.Min1B_60sf_negative = zeros(length(Array.Yaw),length(Array.Azim));
    Array.Max2B_60sf_positive = zeros(length(Array.Yaw),length(Array.Azim));
    Array.Min2B_60sf_negative = zeros(length(Array.Yaw),length(Array.Azim));

    for i=1:length(Yaw)
        indexYaw = find(Yaw(i)==Array.Yaw);
        indexAzim = find(Azim(i)==Array.Azim);

        Array.Max1B(indexYaw,indexAzim) = Max1B(i)/GearRatio;
        Array.Max2B(indexYaw,indexAzim) = Max2B(i)/GearRatio;

        Array.Max1B_2sf(indexYaw,indexAzim) = Max1B_2sf(i);
        Array.Max2B_2sf(indexYaw,indexAzim) = Max2B_2sf(i);

        Array.Max1B_60sf(indexYaw,indexAzim) = Max1B_60sf(i);
        Array.Max2B_60sf(indexYaw,indexAzim) = Max2B_60sf(i);

        Array.Max1B_pp(indexYaw,indexAzim) = Max1B_pp(i);
        Array.Max2B_pp(indexYaw,indexAzim) = Max2B_pp(i);

        Array.Max1B_positive(indexYaw,indexAzim) = Max1B_positive(i);
        Array.Min1B_negative(indexYaw,indexAzim) = Min1B_negative(i);
        Array.Max2B_positive(indexYaw,indexAzim) = Max2B_positive(i);
        Array.Min2B_negative(indexYaw,indexAzim) = Min2B_negative(i);

        Array.Max1B_2sf_positive(indexYaw,indexAzim) = Max1B_2sf_positive(i);
        Array.Min1B_2sf_negative(indexYaw,indexAzim) = Min1B_2sf_negative(i);
        Array.Max2B_2sf_positive(indexYaw,indexAzim) = Max2B_2sf_positive(i);
        Array.Min2B_2sf_negative(indexYaw,indexAzim) = Min2B_2sf_negative(i);

        Array.Max1B_60sf_positive(indexYaw,indexAzim) = Max1B_60sf_positive(i);
        Array.Min1B_60sf_negative(indexYaw,indexAzim) = Min1B_60sf_negative(i);
        Array.Max2B_60sf_positive(indexYaw,indexAzim) = Max2B_60sf_positive(i);
        Array.Min2B_60sf_negative(indexYaw,indexAzim) = Min2B_60sf_negative(i);

    end

    h = actxserver('excel.application');
    % set(h, 'Visible', 1);
    %Create a new work book (excel file)
    wb = h.WorkBooks.Add();
    % Delete old sheets
    for i=1:h.Worksheets.Count-1
        h.Worksheets.Item(1).Delete;
    end

    PrepareResultsSheet(h);

    WriteDataExcelSheet(h,Array.Azim,Array.Yaw,Array.Max1B,'1 Blade - Abs',1,10)
    WriteDataExcelSheet(h,Array.Azim,Array.Yaw,Array.Max2B,'2 Blades - Abs',2,11)
    WriteDataExcelSheet(h,Array.Azim,Array.Yaw,Array.Max1B_2sf,'1 Blade - 2s filter',1,12)
    WriteDataExcelSheet(h,Array.Azim,Array.Yaw,Array.Max2B_2sf,'2 Blades - 2s filter',2,13)
    WriteDataExcelSheet(h,Array.Azim,Array.Yaw,Array.Max1B_60sf,'1 Blade - 60s filter',1,14)
    WriteDataExcelSheet(h,Array.Azim,Array.Yaw,Array.Max2B_60sf,'2 Blades - 60s filter',2,15)
    WriteDataExcelSheet(h,Array.Azim,Array.Yaw,Array.Max1B_pp,'1 Blade - 1s peak to peak',1,16)
    WriteDataExcelSheet(h,Array.Azim,Array.Yaw,Array.Max2B_pp,'2 Blades - 1s peak to peak',2,17)

    % save the file with the given file name, close Excel
    filename = fullfile(OutputFolder,'Results_AllAzim');
    wb.SaveAs(filename);
    wb.Close;
    h.Quit;
    h.delete;

    function [] = WriteDataExcelSheet(h,Azim,Yaw,data,SheetName,NBlades,line)
        % Add a new WorkSheet
        WS = h.Worksheets; WS.Add([], WS.Item(WS.Count));
        set(h.Activesheet,'Name',SheetName);
        
        ActiveRange = get(h.Activesheet,'Range','A1');
        set(ActiveRange, 'Value',  'Yaw\Azim');
        set(ActiveRange.interior, 'Color', [220 230 241] * [1 256 256^2]' );
        
        % Writes Azimuth angles
        cell1 = get (h.Activesheet.Cells,'Item',1,2);
        cell2 = get (h.Activesheet.Cells,'Item',1,length(Azim)+1);
        ActiveRange = get(h.Activesheet,'Range',cell1,cell2);
        set(ActiveRange, 'Value',  Azim');
        set(ActiveRange.interior, 'Color', [220 230 241] * [1 256 256^2]' );
        
        % Writes Wind Directions
        cell1 = get (h.Activesheet.Cells,'Item',2,1);
        cell2 = get (h.Activesheet.Cells,'Item',length(Yaw)+1,1);
        ActiveRange = get(h.Activesheet,'Range',cell1,cell2);
        set(ActiveRange, 'Value',  Yaw);
        set(ActiveRange.interior, 'Color', [220 230 241] * [1 256 256^2]' );
        
        % Writes Extreme torques
        cell1 = get (h.Activesheet.Cells,'Item',2,2);
        cell2 = get (h.Activesheet.Cells,'Item',size(data,1)+1,size(data,2)+1);
        ActiveRange = get(h.Activesheet,'Range',cell1,cell2);
        set(ActiveRange, 'Value',  data, 'NumberFormat',  '0.0');
        
        switch NBlades
            case 1 % If only one blade (Blade 1)
                % Combination 1
                index = find((Azim>=0) & (Azim<=360));
                cell1 = get (h.Activesheet.Cells,'Item',length(Yaw)+3,index(1)+1);
                cell2 = get (h.Activesheet.Cells,'Item',length(Yaw)+3,index(end)+1);
                ActiveRange = get(h.Activesheet,'Range',cell1,cell2);
                set(ActiveRange, 'MergeCells',  'True');
                cell3 = get (h.Activesheet.Cells,'Item',2,index(1)+1);
                cell4 = get (h.Activesheet.Cells,'Item',length(Yaw)+1,index(end)+1);
                set(ActiveRange, 'Value',['=MAX(',get(cell3,'Address'),':',get(cell4,'Address'),')'], 'HorizontalAlignment','3', 'VerticalAlignment','2');
                set(ActiveRange.interior, 'Color', [255 235 156] * [1 256 256^2]' );
                
                sheet_1 = get(h.Worksheets, 'Item', 'Results');
                sheet_1.Activate;
                cell13 = get (h.Activesheet.Cells,'Item',line,1);
                cell14 = get (h.Activesheet.Cells,'Item',line,1);
                ActiveRange = get(h.Activesheet,'Range',cell13,cell14);
                set(ActiveRange, 'Value', SheetName );
                cell15 = get (h.Activesheet.Cells,'Item',line,2);
                cell16 = get (h.Activesheet.Cells,'Item',line,2);
                ActiveRange = get(h.Activesheet,'Range',cell15,cell16);
                set(ActiveRange, 'Value',  ['=''',SheetName,'''!',get(cell1,'Address')], 'NumberFormat',  '0.0');
                
            case 2 % If Blades 1 and 2
                % Combination 1
                index = find((Azim>=0) & (Azim<=360));
                cell1 = get (h.Activesheet.Cells,'Item',length(Yaw)+3,index(1)+1);
                cell2 = get (h.Activesheet.Cells,'Item',length(Yaw)+3,index(end)+1);
                ActiveRange = get(h.Activesheet,'Range',cell1,cell2);
                set(ActiveRange, 'MergeCells',  'True');
                cell3 = get (h.Activesheet.Cells,'Item',2,index(1)+1);
                cell4 = get (h.Activesheet.Cells,'Item',length(Yaw)+1,index(end)+1);
                set(ActiveRange, 'Value',['=MAX(',get(cell3,'Address'),':',get(cell4,'Address'),')'], 'HorizontalAlignment','3', 'VerticalAlignment','2');
                set(ActiveRange.interior, 'Color', [255 235 156] * [1 256 256^2]' );
                
                sheet_1 = get(h.Worksheets, 'Item', 'Results');
                sheet_1.Activate;
                cell9 = get (h.Activesheet.Cells,'Item',line,1);
                cell10 = get (h.Activesheet.Cells,'Item',line,1);
                ActiveRange = get(h.Activesheet,'Range',cell9,cell10);
                set(ActiveRange, 'Value', SheetName );
                cell11 = get (h.Activesheet.Cells,'Item',line,2);
                cell12 = get (h.Activesheet.Cells,'Item',line,2);
                ActiveRange = get(h.Activesheet,'Range',cell11,cell12);
                set(ActiveRange, 'Value',  ['=''',SheetName,'''!',get(cell1,'Address')], 'NumberFormat',  '0.0');
        end
        
    end

    function [] = PrepareResultsSheet(h)
        set(h.Worksheets.Item(1),'Name','Results');
        ActiveRange = get(h.Activesheet,'Range','A1');
        set(ActiveRange, 'Value',  'Turner gear loads - All blade configurations are taken into account (1 Blade: max of blade 1, 2 and 3. 2 Blades: max of blades 1-2, 2-3, 1-3)');
        ActiveRange = get(h.Activesheet,'Range','A2');
        set(ActiveRange, 'Value',  'Combination 1: ');
        ActiveRange = get(h.Activesheet,'Range','A3');
        set(ActiveRange, 'Value',  'Combination 2: ');
        ActiveRange = get(h.Activesheet,'Range','A10');
        set(ActiveRange, 'Value', '1 Blade');
        ActiveRange = get(h.Activesheet,'Range','A11');
        set(ActiveRange, 'Value', '2 Blades');
    end

end
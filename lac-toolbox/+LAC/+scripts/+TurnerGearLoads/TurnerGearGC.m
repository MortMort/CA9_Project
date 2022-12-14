function TurnerGearGC(varargin)

    % Input parser.
    Parser = inputParser;
    Parser.addOptional('filepath_load_paths', []);
    Parser.addOptional('output_folder', []);
    Parser.addOptional('mymbr_limit', []);
	Parser.addOptional('SmomBLD', []);
    Parser.addOptional('GravityCorrection', []);

    % Parse.
    Parser.parse(varargin{:});

    % Set variables.
    filepath_load_paths = Parser.Results.('filepath_load_paths');
    output_folder = Parser.Results.('output_folder');
    mymbr_limit = Parser.Results.('mymbr_limit');
	SmomBLD = Parser.Results.('SmomBLD');
	GravityCorrection = Parser.Results.('GravityCorrection');

    % Definitions.
    load_factor_135 = 1.35; % Load factor.
    mymbr_limit_char = mymbr_limit/1.35; % Limit for MyMBr.

    % Read all lines.
    Fid = fopen(filepath_load_paths);
    Lines = textscan(Fid,'%s','Delimiter','\n');
    loads_folder_list = Lines{1};
    fclose(Fid);

    % Initiate.
    envelope_all_1blade_clockwise = [];
    envelope_all_1blade_counter_clockwise = [];
    envelope_all_2blade_clockwise = [];
    envelope_all_2blade_counter_clockwise = [];

    % Prepare loop.
    i = 0;
    % 1 Blade.
    i = i+1;
    file_list(i).filename = fullfile(output_folder, 'envelope_1blade_clockwise_characteristic.txt');
    file_list(i).load_factor = 1.00;
    file_list(i).type = 'clockwise_1blade';
    i = i+1;
    file_list(i).filename = fullfile(output_folder, 'envelope_1blade_clockwise_design.txt');
    file_list(i).load_factor = load_factor_135;
    file_list(i).type = 'clockwise_1blade';
    i = i+1;
    file_list(i).filename = fullfile(output_folder, 'envelope_1blade_counter_clockwise_characteristic.txt');
    file_list(i).load_factor = 1.00;
    file_list(i).type = 'counter_clockwise_1blade';
    i = i+1;
    file_list(i).filename = fullfile(output_folder, 'envelope_1blade_counter_clockwise_design.txt');
    file_list(i).load_factor = load_factor_135;
    file_list(i).envelope_all = envelope_all_1blade_counter_clockwise;
    file_list(i).type = 'counter_clockwise_1blade';

    % 2 Blades.
    i = i+1;
    file_list(i).filename = fullfile(output_folder, 'envelope_2blade_clockwise_characteristic.txt');
    file_list(i).load_factor = 1.00;
    file_list(i).type = 'clockwise_2blade';
    i = i+1;
    file_list(i).filename = fullfile(output_folder, 'envelope_2blade_clockwise_design.txt');
    file_list(i).load_factor = load_factor_135;
    file_list(i).type = 'clockwise_2blade';
    i = i+1;
    file_list(i).filename = fullfile(output_folder, 'envelope_2blade_counter_clockwise_characteristic.txt');
    file_list(i).load_factor = 1.00;
    file_list(i).type = 'counter_clockwise_2blade';
    i = i+1;
    file_list(i).filename = fullfile(output_folder, 'envelope_2blade_counter_clockwise_design.txt');
    file_list(i).load_factor = load_factor_135;
    file_list(i).envelope_all = envelope_all_1blade_counter_clockwise;
    file_list(i).type = 'counter_clockwise_2blade';


    % Open files.
    for iFile=1:length(file_list)
        file_list(iFile).fid = fopen(file_list(iFile).filename, 'w');
    end

    % Find maximum length of foldername.
    foldernames = [];
    max_length_folder_names = 0;
    for iVariant=1:length(loads_folder_list)
        % Set local.
        loads_folder = loads_folder_list{iVariant};

        % Remove possible backslash to make below code robust.
        if strcmp(loads_folder(end),'\');
            loads_folder = fileparts(loads_folder);
        end

        % Get folder name of the folder "before" the loads folder.
        out = regexp(loads_folder,'\','split');
        foldername = out{end-1};
        foldernames{end+1} = foldername;
        max_length_folder_names = max(max_length_folder_names,length(foldername));

        % Save.
        loads_folder_list{iVariant} = loads_folder;
    end

    % Loop.
    for iVariant=1:length(loads_folder_list)

        % Set flag.
        is_first_iteration = iVariant==1;
        is_last_iteration = iVariant==length(loads_folder_list);

        % Set local.
        loads_folder = loads_folder_list{iVariant};
        int_folder = fullfile(loads_folder, 'INT');
        foldername = foldernames{iVariant};

        % Output folder.
        output_folder_local = fullfile(output_folder, foldername);

        % Calculate turner gear loads and save to a mat file.
        ForceIntFileRead = false;
%         ForceIntFileRead = true;
        %out_struct = LAC.vts.CalculateTurnerGearExtremeLoads(int_folder, 'OutputFolder', output_folder_local, 'ForceIntFileRead', ForceIntFileRead);
        out_struct = CalculateTurnerGearExtremeLoadsGC(int_folder, SmomBLD, GravityCorrection, 'OutputFolder', output_folder_local, 'ForceIntFileRead', ForceIntFileRead);

        % Set envelopes.
        envelope_1blade_clockwise = out_struct.out_struct_clockwise.one_blade_abs_envelope;
        envelope_1blade_counter_clockwise = out_struct.out_struct_counter_clockwise.one_blade_abs_envelope;
        envelope_2blade_clockwise = out_struct.out_struct_clockwise.two_blade_abs_envelope;
        envelope_2blade_counter_clockwise = out_struct.out_struct_counter_clockwise.two_blade_abs_envelope;

        % Save.
    %     file_list(i).type = 'counter_clockwise';

        % Save.
        envelope_all_1blade_clockwise(iVariant,:) = envelope_1blade_clockwise;
        envelope_all_1blade_counter_clockwise(iVariant,:) = envelope_1blade_counter_clockwise;
        envelope_all_2blade_clockwise(iVariant,:) = envelope_2blade_clockwise;
        envelope_all_2blade_counter_clockwise(iVariant,:) = envelope_2blade_counter_clockwise;

        % Print to file.
        for iFile=1:length(file_list)
            % Set local.
            fid = file_list(iFile).fid;
            load_factor = file_list(iFile).load_factor;
            type = file_list(iFile).type;

            % Set envelope to use.
            if strcmp(type,'clockwise_1blade')
                envelope = envelope_1blade_clockwise;
            elseif strcmp(type,'counter_clockwise_1blade')
                envelope = envelope_1blade_counter_clockwise;
            elseif strcmp(type,'clockwise_2blade')
                envelope = envelope_2blade_clockwise;
            elseif strcmp(type,'counter_clockwise_2blade')
                envelope = envelope_2blade_counter_clockwise;
            end

            % Format for folder name / calculation id.
            format_folder = ['%' num2str(max_length_folder_names+5) 's'];

            % Write wind direction if first iteration.
            if is_first_iteration
                % Placeholder where foldername / calculation id will be printed.
                fprintf(fid,format_folder,'');

                WindDirections = out_struct.out_struct_clockwise.yaw;
                for iWindDirection=1:length(WindDirections)
                    % Print.
                    fprintf(fid,'%8.2f',WindDirections(iWindDirection));
                end
                % New line.
                fprintf(fid,'\n');
            end

            % Foldername / calculation id.
            fprintf(fid,format_folder,foldername);

            % Write data to envelope file.
            for iValue=1:length(envelope)
                % Print.
                fprintf(fid,'%8.2f',envelope(iValue)*load_factor);
            end
            % New line.
            fprintf(fid,'\n');
        end

        % ************************
        % Plot 1&2 blades and counter and counter clockwise.
        % ************************
        % Initiate.
        figure("Name",'Envelope');
        hold on;
        plot_handles = [];
        legend_texts = {};

        % Plot.
%         load_factor = load_factor_135;
        load_factor = 1;
        plot_handles(end+1) = plot(WindDirections, envelope_1blade_clockwise*load_factor,'-', 'color','b','linewidth',3);
        plot_handles(end+1) = plot(WindDirections, envelope_1blade_counter_clockwise*load_factor,'-', 'color','r','linewidth',1);
        plot_handles(end+1) = plot(WindDirections, envelope_2blade_clockwise*load_factor,'-', 'color','g','linewidth',3);
        plot_handles(end+1) = plot(WindDirections, envelope_2blade_counter_clockwise*load_factor,'-', 'color','r','linewidth',1);

        % Save.
        legend_texts{end+1} = '1 blade, clockwise';
        legend_texts{end+1} = '1 blade, counter-clockwise';
        legend_texts{end+1} = '2 blade, clockwise';
        legend_texts{end+1} = '2 blade, counter-clockwise';

        % Plot design limit.
        plot_handles(end+1) = plot(xlim, [mymbr_limit, mymbr_limit],'-', 'color','r');
        legend_texts{end+1} = 'Design limit';

        % Annotate.
        xlabel('Wind direction [deg]');
        ylabel('Main shaft torsion, MyMBr [kNm]');
        set(gca,'ylim',[0, mymbr_limit*1.50]);
        set(gca,'xlim',[0, 360]);
        grid on;
        set(gca,'box','on');
        set(gcf,'units','centimeter','paperunits','centimeter','paperposition',[0,0,20,20]);
        legend(plot_handles,legend_texts,'Interpreter','tex', 'Location', 'southeast');
        filename = fullfile(output_folder_local,'envelopes.png');
        saveas(gcf,filename,'png');
        close Envelope
    end

    % Print to file.
    for iFile=1:length(file_list)
        % Set local.
        fid = file_list(iFile).fid;
        load_factor = file_list(iFile).load_factor;
        type = file_list(iFile).type;

        % Set envelope to use.
        if strcmp(type,'clockwise')

        elseif strcmp(type,'counter_clockwise')
            envelope_all = envelope_all_1blade_counter_clockwise;
        end

        if strcmp(type,'clockwise_1blade')
            envelope_all = envelope_all_1blade_clockwise;
        elseif strcmp(type,'counter_clockwise_1blade')
            envelope_all = envelope_all_1blade_counter_clockwise;
        elseif strcmp(type,'clockwise_2blade')
            envelope_all = envelope_all_2blade_clockwise;
        elseif strcmp(type,'counter_clockwise_2blade')
            envelope_all = envelope_all_2blade_counter_clockwise;
        end

        % Placeholder where foldername / calculation id will be printed.
        fprintf(fid,format_folder,'Envelope');

        % Print overall envelope.
        envelope_global = max(envelope_all,[],1); % Take maximum for each column (operate along dim=1).
        for iValue=1:length(envelope_global)
            % Print.
            fprintf(fid,'%8.2f',envelope_global(iValue)*load_factor);
        end
        % New line.
        fprintf(fid,'\n');

        % Write the largest max value.
        fprintf(fid,'%8.2f',max(envelope_global)*load_factor);
    end

    % Close files.
    for iFile=1:length(file_list)
        fclose(file_list(iFile).fid);
    end

    % ************************
    % Plot envelope for design value.
    % ************************
    % Print to file.
    for iFile=1:length(file_list)
        % Set local.
        fid = file_list(iFile).fid;
        load_factor = file_list(iFile).load_factor;
        type = file_list(iFile).type;
        filename_txt = file_list(iFile).filename;

        % Set envelope to use.    
        if strcmp(type,'clockwise_1blade')
            envelope_all = envelope_all_1blade_clockwise;
        elseif strcmp(type,'counter_clockwise_1blade')
            envelope_all = envelope_all_1blade_counter_clockwise;
        elseif strcmp(type,'clockwise_2blade')
            envelope_all = envelope_all_2blade_clockwise;
        elseif strcmp(type,'counter_clockwise_2blade')
            envelope_all = envelope_all_2blade_counter_clockwise;
        end

        % Initiate figure.
        figure;
        hold on;
        colors = {'m','g','b','k','y','r'};
        plot_handles = [];
        legend_texts = {};
        for iVariant=1:length(foldernames);
            % Set local.
            foldername = foldernames{iVariant};
            envelope = envelope_all(iVariant,:);
            color = colors{iVariant};

            % Plot.
            plot_handles(end+1) = plot(WindDirections, envelope*load_factor,'-', 'color',color);

            % Save.
            legend_texts{end+1} = strrep(foldername,'_','\_');
        end

        % Plot design limit.
        mymbr_limit = mymbr_limit_char * load_factor;
        plot_handles(end+1) = plot(xlim, [mymbr_limit, mymbr_limit],'-', 'color','r');

        % Save.
        legend_texts{end+1} = 'Design limit';

        % Annotate.
        xlabel('Wind direction [deg]');
        ylabel('Main shaft torsion, MyMBr [kNm]');
        set(gca,'ylim',[0, mymbr_limit*1.50]);
        set(gca,'xlim',[0, 360]);
        grid on;
        set(gca,'box','on');
        set(gcf,'units','centimeter','paperunits','centimeter','paperposition',[0,0,20,20]);
        legend(plot_handles,legend_texts,'Interpreter','tex');
        filename = strrep(filename_txt,'.txt','.png');
        saveas(gcf,filename,'png');
        close all;
    end

    % Close all figures.
    close all;
end
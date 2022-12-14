classdef GUI_MM < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                      matlab.ui.Figure
        LeftPanel                     matlab.ui.container.Panel
        WritetoxlsxButton             matlab.ui.control.Button
        OtherButton                   matlab.ui.control.Button
        RunselectionButton            matlab.ui.control.Button
        OptionsPanel                  matlab.ui.container.Panel
        PostloadsDropDown             matlab.ui.control.DropDown
        PostloadsDropDown_2Label      matlab.ui.control.Label
        ToleranceEditField            matlab.ui.control.NumericEditField
        ToleranceEditFieldLabel       matlab.ui.control.Label
        UseVLDcodecCheckBox           matlab.ui.control.CheckBox
        ClearButton                   matlab.ui.control.Button
        ImportmodelsButton            matlab.ui.control.Button
        TextArea                      matlab.ui.control.TextArea
        Label                         matlab.ui.control.Label
        GUIMasterModelSelectionLabel  matlab.ui.control.Label
    end

    
    properties (Access = private)
        path_info
        path_availability
        paths
        outpath
        loadData
        sensors
        solutions
        refsys
    end
    
    methods (Access = private)  
        function setPromptFcn(app,jTextArea,eventData,newPrompt)
            % Prevent overlapping reentry due to prompt replacement
            persistent inProgress
            if isempty(inProgress)
                inProgress = 1;  %#ok unused
            else
                return;
            end
             
            try
                cwText = char(jTextArea.getText);
                app.TextArea.Value = cwText;
                scroll(app.TextArea, 'bottom')
    %             pause(0.02);
            catch
                % Never mind - ignore errors...
            end
            % Enable new callbacks now that the prompt has been modified
            inProgress = [];
        end  
    end      

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app)
            clc;
            fprintf('Import models for selection.\n\n')         
            try % initializing cmd window print to gui
                jDesktop = com.mathworks.mde.desk.MLDesktop.getInstance;
                jCmdWin = jDesktop.getClient('Command Window');
                jTextArea = jCmdWin.getComponent(0).getViewport.getView;
                set(jTextArea,'CaretUpdateCallback',@app.setPromptFcn)
            catch
                warndlg('fatal error.');
            end
        end

        % Button pushed function: ImportmodelsButton
        function ImportmodelsButtonPushed(app, event)
            [file,path] = uigetfile('*.txt', 'Select a pathlist.txt file.'); % example in repo??
            figure(app.UIFigure)
            
            [path_info,path_funcs] = LAC.scripts.MasterModel.tools.PathInfo(fullfile(path,file));
            app.path_info = path_info.Paths;
            app.path_availability = path_info.Availability;
            app.paths = path_funcs.path;
            app.outpath = path;
            
            disp('Data availability (..\MainLoad.txt):')
            disp(' ')
            disp(path_info)
            fprintf('Verify options before running.\n\n')
            
            % GRS check
            app.refsys = LAC.scripts.MasterModel.tools.detectRefSys(path_info);
        end

        % Button pushed function: ClearButton
        function ClearButtonPushed(app, event)
            clc
            clear all; %  evalin('base','clear A B')
        end

        % Value changed function: UseVLDcodecCheckBox
        function UseVLDcodecCheckBoxValueChanged(app, event)
            app.UseVLDcodecCheckBox.Value;            
        end

        % Value changed function: ToleranceEditField
        function ToleranceEditFieldValueChanged(app, event)
            app.ToleranceEditField.Value;            
        end

        % Callback function
        function ReferencesystemDropDownValueChanged(app, event)
            app.ReferencesystemDropDown.Value;
        end

        % Value changed function: PostloadsDropDown
        function PostloadsDropDownValueChanged(app, event)
            app.PostloadsDropDown.Value;            
        end

        % Button pushed function: RunselectionButton
        function RunselectionButtonPushed2(app, event)
            fprintf('Running algorithm...\n\n')

            % waitbar
            f = waitbar(0,'Applying options.');
            pause(1)

            % data
            available_data = app.path_availability;
            data_paths = app.paths(available_data);
           
            % options
            vld_selection = app.UseVLDcodecCheckBox.Value;
            fam_method = str2double(app.PostloadsDropDown.Value);                      
            
            waitbar(.1,f,'Loading model data');
            pause(.5)          
                            
            [app.loadData, app.sensors] = LAC.scripts.MasterModel.tools.get_data_DRT_TWR(data_paths,app.refsys,fam_method,vld_selection);

            waitbar(.8,f,'Running algorithm');
            pause(1)

            app.solutions = LAC.scripts.MasterModel.choose_turbines_glpk(app.loadData,app.ToleranceEditField.Value,true);
            
            waitbar(1,f,'Finishing');
            pause(1)
            close(f)

            fprintf('Accept solution (write to .xlsx) or select other.\n\n')
        end

        % Callback function
        function RunselectionButtonPushed(app, event)
            app.solutions = LAC.scripts.MasterModel.choose_turbines_glpk(app.loadData,app.ToleranceEditField.Value,true);
        end

        % Button pushed function: OtherButton
        function OtherButtonPushed(app, event)
            % pop up with list of solutions
            fig = uifigure('Name','Model selection');
            fig.Position(3:4) = [350 180];
            fig.WindowStyle = 'modal';

            % label1
            lbl = uilabel(fig);
            lbl.Text = '<b>Master model solutions:</b>';
            lbl.Interpreter = 'html';
            lbl.FontSize = 14;
            lbl.Position(1:4) = [40 110 220 60];

            % label2
            lbl2 = uilabel(fig);
            lbl2.Text = '<em>(Close window after selection).</em>';
            lbl2.Interpreter = 'html';
            lbl2.FontSize = 10;
            lbl2.Position(1:4) = [40 100 220 60];
            
            % drop-down menu
            items = cellfun(@(x) cellstr(join(string(find(x>0)),'-')), app.solutions.feasible_solutions);
            [~,~,ic] = unique(items,'stable');

            dd = uidropdown(fig,...
                'Items',items,...
                'ItemsData',ic,...
                'Position',[40 80 220 40]); 

                % close request
                fig.CloseRequestFcn = @(src,event)my_closereq(src);
                function my_closereq(fig)
                    selection = uiconfirm(fig,'Accept selection & continue?',...
                        'Confirmation');
                    switch selection
                        case 'OK'
                            delete(fig)
                        case 'Cancel'
                            return
                    end
                end            
    
            % overwrite (default) solutions
            app.solutions.id = dd.Value;
            app.solutions.choices = find(app.solutions.feasible_solutions{app.solutions.id}>0);
            app.solutions.lf_best = app.solutions.feasible_solutions_load_factors{app.solutions.choices};
            app.solutions.lf_matrix = app.solutions.lf_matrix_raw(:,app.solutions.choices); 
        end

        % Button pushed function: WritetoxlsxButton
        function WritetoxlsxButtonPushed(app, event)
            fprintf('Solution accepted.\n')
            fprintf('Writing to .xlsx.\n\n')
            
             % add sensors to solutions struct
            app.solutions.sensors = app.sensors;

            % .xlsx naming
            outDir=dir(app.outpath);
            fileIdx=size(outDir,1)-1;
            timerun=datetime('now');
            dateref=datestr(timerun,'yyyymmdd_HHMM');
            fileName=sprintf('%03d_MasterModelSummary_%s.xls',fileIdx,dateref);
            
            excelStatus = LAC.scripts.MasterModel.tools.outToExcel(fileName,app.outpath,app.paths,app.loadData,app.solutions);
            if excelStatus == 1
                fprintf('Summary of down-selection available in %s\n',[app.outpath filesep fileName])
            else
                disp('An error occured when writing a summary to the excel file');
            end
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [100 100 866 620];
            app.UIFigure.Name = 'MATLAB App';

            % Create LeftPanel
            app.LeftPanel = uipanel(app.UIFigure);
            app.LeftPanel.Position = [1 1 866 620];

            % Create GUIMasterModelSelectionLabel
            app.GUIMasterModelSelectionLabel = uilabel(app.LeftPanel);
            app.GUIMasterModelSelectionLabel.FontSize = 16;
            app.GUIMasterModelSelectionLabel.FontWeight = 'bold';
            app.GUIMasterModelSelectionLabel.Position = [8 590 228 22];
            app.GUIMasterModelSelectionLabel.Text = 'GUI - Master Model Selection';

            % Create Label
            app.Label = uilabel(app.LeftPanel);
            app.Label.HorizontalAlignment = 'right';
            app.Label.Position = [35 448 55 22];
            app.Label.Text = '';

            % Create TextArea
            app.TextArea = uitextarea(app.LeftPanel);
            app.TextArea.Position = [8 78 851 392];

            % Create ImportmodelsButton
            app.ImportmodelsButton = uibutton(app.LeftPanel, 'push');
            app.ImportmodelsButton.ButtonPushedFcn = createCallbackFcn(app, @ImportmodelsButtonPushed, true);
            app.ImportmodelsButton.BackgroundColor = [0.902 0.902 0.902];
            app.ImportmodelsButton.FontWeight = 'bold';
            app.ImportmodelsButton.Tooltip = {'Import models from pathlist.txt.'};
            app.ImportmodelsButton.Position = [180 479 217 105];
            app.ImportmodelsButton.Text = 'Import models';

            % Create ClearButton
            app.ClearButton = uibutton(app.LeftPanel, 'push');
            app.ClearButton.ButtonPushedFcn = createCallbackFcn(app, @ClearButtonPushed, true);
            app.ClearButton.FontWeight = 'bold';
            app.ClearButton.Tooltip = {'Clear variables and command window. Reset.'};
            app.ClearButton.Position = [405 479 119 105];
            app.ClearButton.Text = 'Clear';

            % Create OptionsPanel
            app.OptionsPanel = uipanel(app.LeftPanel);
            app.OptionsPanel.Title = 'Options';
            app.OptionsPanel.BackgroundColor = [0.9294 0.6941 0.1255];
            app.OptionsPanel.FontAngle = 'italic';
            app.OptionsPanel.FontWeight = 'bold';
            app.OptionsPanel.Position = [10 479 163 105];

            % Create UseVLDcodecCheckBox
            app.UseVLDcodecCheckBox = uicheckbox(app.OptionsPanel);
            app.UseVLDcodecCheckBox.ValueChangedFcn = createCallbackFcn(app, @UseVLDcodecCheckBoxValueChanged, true);
            app.UseVLDcodecCheckBox.Tooltip = {'Enabled (default). If disabled VLD sensors for the drivetrain is estimated using legacy matlab scripts.'};
            app.UseVLDcodecCheckBox.Text = '           Use VLD codec';
            app.UseVLDcodecCheckBox.WordWrap = 'on';
            app.UseVLDcodecCheckBox.Position = [9 36 168 22];
            app.UseVLDcodecCheckBox.Value = true;

            % Create ToleranceEditFieldLabel
            app.ToleranceEditFieldLabel = uilabel(app.OptionsPanel);
            app.ToleranceEditFieldLabel.Position = [63 58 102 22];
            app.ToleranceEditFieldLabel.Text = 'Tolerance';

            % Create ToleranceEditField
            app.ToleranceEditField = uieditfield(app.OptionsPanel, 'numeric');
            app.ToleranceEditField.ValueChangedFcn = createCallbackFcn(app, @ToleranceEditFieldValueChanged, true);
            app.ToleranceEditField.HorizontalAlignment = 'left';
            app.ToleranceEditField.Tooltip = {'0.01 (default). Tolerance on loads during master model selection.'};
            app.ToleranceEditField.Position = [8 58 44 22];
            app.ToleranceEditField.Value = 0.01;

            % Create PostloadsDropDown_2Label
            app.PostloadsDropDown_2Label = uilabel(app.OptionsPanel);
            app.PostloadsDropDown_2Label.HorizontalAlignment = 'right';
            app.PostloadsDropDown_2Label.Position = [54 15 63 22];
            app.PostloadsDropDown_2Label.Text = 'Postloads';

            % Create PostloadsDropDown
            app.PostloadsDropDown = uidropdown(app.OptionsPanel);
            app.PostloadsDropDown.Items = {'0', '1', '2'};
            app.PostloadsDropDown.ValueChangedFcn = createCallbackFcn(app, @PostloadsDropDownValueChanged, true);
            app.PostloadsDropDown.Tooltip = {'Approach to family methodology. '; '0: Normal i.e. Postloads. '; '1: Other folder for tilt and tower.'; '2: Other folder for all (except blade, hub).'};
            app.PostloadsDropDown.Position = [8 15 44 22];
            app.PostloadsDropDown.Value = '0';

            % Create RunselectionButton
            app.RunselectionButton = uibutton(app.LeftPanel, 'push');
            app.RunselectionButton.ButtonPushedFcn = createCallbackFcn(app, @RunselectionButtonPushed2, true);
            app.RunselectionButton.BackgroundColor = [0.902 0.902 0.902];
            app.RunselectionButton.FontWeight = 'bold';
            app.RunselectionButton.Position = [10 6 275 63];
            app.RunselectionButton.Text = 'Run selection';

            % Create OtherButton
            app.OtherButton = uibutton(app.LeftPanel, 'push');
            app.OtherButton.ButtonPushedFcn = createCallbackFcn(app, @OtherButtonPushed, true);
            app.OtherButton.FontWeight = 'bold';
            app.OtherButton.Position = [297 6 275 63];
            app.OtherButton.Text = 'Other';

            % Create WritetoxlsxButton
            app.WritetoxlsxButton = uibutton(app.LeftPanel, 'push');
            app.WritetoxlsxButton.ButtonPushedFcn = createCallbackFcn(app, @WritetoxlsxButtonPushed, true);
            app.WritetoxlsxButton.FontWeight = 'bold';
            app.WritetoxlsxButton.Position = [584 6 275 63];
            app.WritetoxlsxButton.Text = 'Write to .xlsx';

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = GUI_MM

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.UIFigure)

            % Execute the startup function
            runStartupFcn(app, @startupFcn)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.UIFigure)
        end
    end
end
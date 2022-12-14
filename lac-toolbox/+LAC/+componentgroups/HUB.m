classdef HUB < hgsetget
    properties
        % Properties to handle the pitch table.
        ControlVoltages
        PitchMoments
        PitchRates
        
        % Remaining parameters.
        D, d, Rho, Pp, Pt, a_reg_cv, a_eq_a_port, a_eq_b_port, a_reg_acc, 
        R, M_pi
        
        % "Misc." parameters.
        order, timeconst, Ksi, tpsdelay, Deadband, PistonPosxMin1, PistonPosxMin2, 
        PistonPosxMin3, PistonPosxMax1, PistonPosxMax2, PistonPosxMax3, PiMinG1, 
        PiMinG2, PiMinG3, PiMaxG1, PiMaxG2, PiMaxG3, tupd0, tupd1, tupd2, 
        EMCpitchspeedresp, Frequency, DampingRatio, a_0, a_1, a_2, a_3, a_4, 
        PosVgain, PosOffset, Theta_k, c_pitch_1, c_pitch_2, c_pitch_3, c_pitch_4, 
        TBD1, TBD2
    end
    
    methods
        function Self = ReadFile_000_pitch_table(Self, filename)
            % Read all lines.
            Fid = fopen(filename);
            Lines = textscan(Fid,'%s','delimiter','\n');
            Lines = Lines{1};
            fclose(Fid);
            
            % The original/full format of the "hub" file that contains the pitch table, also contains other parameters. Try to read these. If if does not succeed, then at least try to read the pitch table (further down in the code).
            
            % Look for header.
            index_list = ~cellfun(@isempty,regexp(Lines,regexptranslate('escape','YAW RELATED INFO')));
            iline_start = find(index_list==1);

            % If the header is not there, then do not attempt to read parameters.
            if isempty(iline_start)
                warning('The "PITCH & YAW RELATED INFO" header was not located. Skipping read of parameters.');
            else

                % Parse line 7. Example: "D=140.0[mm] 	 d=90.0[mm]"
                Line = Lines{cellfun(@(x) ~isempty(x),strfind(Lines,'D='))};
                Result = regexp(Line, 'D=(.*?)[', 'tokens');
                Self.D = str2double(Result{1});
                Result = regexp(Line, 'd=(.*?)[', 'tokens');
                Self.d = str2double(Result{1});

                % Parse line 10. Example: "Rho=870.0[kg/m3] 	 Pp=250.0[bar] Pt=1.0[bar]"
                Line = Lines{cellfun(@(x) ~isempty(x),strfind(Lines,'Rho='))};
                Result = regexp(Line, 'Rho=(.*?)[', 'tokens');
                Self.Rho = str2double(Result{1});
                Result = regexp(Line, 'Pp=(.*?)[', 'tokens');
                Self.Pp = str2double(Result{1});
                Result = regexp(Line, 'Pt=(.*?)[', 'tokens');
                Self.Pt = str2double(Result{1});

                % Parse line 19. Example: "a_reg_cv=95.0[mm2] a_eq_a_port=33.2[mm2] 	 a_eq_b_port=18.1[mm2] a_reg_acc=113.1[mm2]"
                Line = Lines{cellfun(@(x) ~isempty(x),strfind(Lines,'a_reg_cv'))};
                Result = regexp(Line, 'a_reg_cv=(.*?)[', 'tokens');
                Self.a_reg_cv = str2double(Result{1});
                Result = regexp(Line, 'a_eq_a_port=(.*?)[', 'tokens');
                Self.a_eq_a_port = str2double(Result{1});
                Result = regexp(Line, 'a_eq_b_port=(.*?)[', 'tokens');
                Self.a_eq_b_port = str2double(Result{1});

                % Parse line 22. Example: "R=0.538[m]"
                Line = Lines{cellfun(@(x) ~isempty(x),strfind(Lines,'c='))};
                Result = regexp(Line, 'c=(.*?)[', 'tokens');
                Self.R = str2double(Result{1});

                % Parse line 25. Example: "M_pi=68.950[kNm]"
                Line = Lines{cellfun(@(x) ~isempty(x),strfind(Lines,'M_pi='))};
                Result = regexp(Line, 'M_pi=(.*?)[', 'tokens');
                Self.M_pi = str2double(Result{1});

                % Parse pitch moments.
                Line = Lines{find(cellfun(@(x) ~isempty(x),strfind(Lines,'[kNm]')))+1};
                Result = regexp(Line, '(-?.*?) \[.*?\]', 'tokens');
                Self.PitchMoments = cellfun(@(x) str2double(x), Result);
            end
            
            % Find starting line for table.            
            index_list = ~cellfun(@isempty,regexp(Lines,'.*TABLE START.*'));
            iline_header = find(index_list);
            
            % Parse pitch moments.
            Line = Lines{iline_header+2};
            Result = regexp(Line, '(-?.*?) \[.*?\]', 'tokens');
            Self.PitchMoments = cellfun(@(x) str2double(x), Result);
            
            % Parse remaining part of pitch table (remaining lines).
            ControlVoltages = [];
            PitchRates = [];
            for iline=iline_header+3:length(Lines)
                % Set line.
                Line = Lines{iline};
                
                % Skip possible empty lines.
                if isempty(strtrim(Line))
                    continue
                end
                
                % Parse line.
                Result = regexp(Line, '(-?\d+.?\d+)', 'tokens');
                
                % Set values.
                ControlVoltages(end+1) = str2double(Result{1});
                PitchRates(end+1,:) = cellfun(@(x) str2double(x), Result(2:end));
            end
            Self.ControlVoltages = ControlVoltages;
            Self.PitchRates = PitchRates;
        end
        function Self = ReadFile_001_misc_parameters(Self, filename)
            % Read all lines.
            Fid = fopen(filename);
            Lines = textscan(Fid,'%s','delimiter','\n');
            Lines = Lines{1};
            
            % Loop through lines.
            nLines = length(Lines);
            for iLine=1:nLines
                % Set local.
                Line = Lines{iLine};
                
                % Parse.
                Result = regexp(Line, '(?<parameter_name>.+)=(?<parameter_value>.+)', 'names');
                parameter_name = strtrim(Result.parameter_name);
                parameter_value = str2double(Result.parameter_value);
                
                % Set value.
                Self.(parameter_name) = parameter_value;
            end
        end
    end
end
   

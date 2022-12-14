classdef PitchFile < hgsetget
    properties
        % Properties to handle the pitch table.
        ControlVoltages
        PitchMoments
        PitchRates
        
        % Remaining parameters.
        D, d, Rho, Pp, Pt, a_reg_cv, a_eq_a_port, a_eq_b_port, a_reg_acc, 
        R, M_pi        
    end
    
    methods
        function Self = ReadFile(Self, filename)
            % Read all lines.
            Fid = fopen(filename, 'r');
            Lines = textscan(Fid,'%s','delimiter','\n');
            Lines = Lines{1};
            fclose(Fid);

            % Parse line 7. Example: "D=140.0[mm] 	 d=90.0[mm]"
            Line = Lines{7};
            Result = regexp(Line, 'D=(.*?)[', 'tokens');
            Self.D = str2double(Result{1});
            Result = regexp(Line, 'd=(.*?)[', 'tokens');
            Self.d = str2double(Result{1});
            
            % Parse line 10. Example: "Rho=870.0[kg/m3] 	 Pp=250.0[bar] Pt=1.0[bar]"
            Line = Lines{10};
            Result = regexp(Line, 'Rho=(.*?)[', 'tokens');
            Self.Rho = str2double(Result{1});
            Result = regexp(Line, 'Pp=(.*?)[', 'tokens');
            Self.Pp = str2double(Result{1});
            Result = regexp(Line, 'Pt=(.*?)[', 'tokens');
            Self.Pt = str2double(Result{1});
            
            % Parse line 19. Example: "a_reg_cv=95.0[mm2] a_eq_a_port=33.2[mm2] 	 a_eq_b_port=18.1[mm2] a_reg_acc=113.1[mm2]"
            Line = Lines{19};
            Result = regexp(Line, 'a_reg_cv=(.*?)[', 'tokens');
            Self.a_reg_cv = str2double(Result{1});
            Result = regexp(Line, 'a_eq_a_port=(.*?)[', 'tokens');
            Self.a_eq_a_port = str2double(Result{1});
            Result = regexp(Line, 'a_eq_b_port=(.*?)[', 'tokens');
            Self.a_eq_b_port = str2double(Result{1});
            
            % Parse line 22. Example: "R=0.538[m]"
            Line = Lines{22};
            Result = regexp(Line, 'R=(.*?)[', 'tokens');
            Self.R = str2double(Result{1});
            
            % Parse line 25. Example: "M_pi=68.950[kNm]"
            Line = Lines{25};
            Result = regexp(Line, 'M_pi=(.*?)[', 'tokens');
            Self.M_pi = str2double(Result{1});
            
            % Parse pitch moments.
            Line = Lines{31};
            Result = regexp(Line, '(-?.*?) \[.*?\]', 'tokens');
            Self.PitchMoments = cellfun(@(x) str2double(x), Result);
            
            % Parse remaining part of pitch table (remaining lines).
            ControlVoltages = [];
            PitchRates = [];
            for iline=32:length(Lines)
                % Set line.
                Line = Lines{iline};
                
                % Skip possible empty lines.
                if isempty(strtrim(Line))
                    continue
                end
                
                % Parse line.
                Result = regexp(Line, '(-?\d+.?\d+?)', 'tokens');
                
                % Set values.
                ControlVoltages(end+1) = str2double(Result{1});
                PitchRates(end+1,:) = cellfun(@(x) str2double(x), Result(2:end));
            end
            Self.ControlVoltages = ControlVoltages;
            Self.PitchRates = PitchRates;
        end
    end
end
   

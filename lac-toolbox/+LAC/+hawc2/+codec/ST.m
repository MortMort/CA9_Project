classdef ST
    properties
        filename char
        nMainSet double
        nSubset double
        parameters cell
        units cell
        Dataset cell        
    end
    methods (Static)
        function s = decode(Coder)
            file_data   = Coder.readFile;
            fileContent = file_data{1};
            s = eval(mfilename('class')); 
                        
            [s.filename] = Coder.getSource;            
           
            s.nMainSet = str2num(fileContent{1});
            % If more than one main set (first line >1) then script does
            % not work yet
            if s.nMainSet ~= 1
                disp('More than one main set in ST file, this is not supported by the script yet');
                return;
            end
            
            % Check number of subsets
            s.nSubset = 0;
            flagContinue = true;
            while flagContinue
                tmp = strfind(fileContent,['$',num2str(s.nSubset+1)]);
                tmp2 = find(~cellfun(@isempty,tmp));
                if ~isempty(tmp2)
                    s.nSubset = s.nSubset + 1;
                    s.Dataset{1,s.nSubset}.LineBegin = tmp2;                    
                else
                    flagContinue = false;
                end
            end                   
            s.parameters = {'r'    'm'    'x_cg'    'y_cg'    'ri_x'    'ri_y'    'x_sh'    'y_sh'    'E'    'G'    'I_x'    'I_y'    'I_xy'    'k_x'    'k_y'    'A'    'theta_s'    'x_e' 'y_e'};
            s.units      = {'[m]'    'kg/m'    '[m]'    '[m]'    '[m]'    '[m]'    '[m]'    '[m]'    '[N/m^2]' '[N/m^2]'    '[m^4]'    '[m^4]'    '[m^4]'    '--'    '--'    '[m^2]'    '[deg]' '[m]'    '[m]'};
            
            for iDataset = 1:s.nSubset
                data = textscan(fileContent{s.Dataset{1,iDataset}.LineBegin},'%s %f');
                s.Dataset{1,iDataset}.nSections = data{2};
                for iSection=1:s.Dataset{1,iDataset}.nSections
                    data = textscan(fileContent{s.Dataset{1,iDataset}.LineBegin+iSection},'%f',19);
                    table(:,iSection) = data{1};
                end
                
                for iParameter = 1:length(s.parameters)
                    s.Dataset{1,iDataset}.SectionTable.(s.parameters{iParameter}) = table(iParameter,:)';
                end
            end
        end
    end
    methods
        function encode(self, filename)
            FID = fopen(filename,'wt');
            fprintf(FID,'1 \n');
            fprintf(FID,'#1 \n');
            
            for iSubset = 1:self.nSubset
                formatstr = sprintf('%s','%8s\t\t ');
                for iHeader=1:length(self.parameters)-1; formatstr = sprintf('%s%s',formatstr,'%8s\t\t '); end
                formatstr = sprintf('%s%s',formatstr,'\n');
                fprintf(FID,formatstr,self.parameters{:});
                fprintf(FID,formatstr,self.units{:});

                fprintf(FID,'$%i %i\n',iSubset,self.Dataset{1,iSubset}.nSections);                
                
                for iParameter = 1:length(self.parameters)
                    table(iParameter,:) = self.Dataset{1,iSubset}.SectionTable.(self.parameters{iParameter});
                end
                for iSection=1:self.Dataset{1,iSubset}.nSections
                    fprintf(FID,' %7.3f\t\t%8.3f\t\t%8.4f\t\t%8.4f\t\t%8.4f\t\t%8.4f\t\t%8.4f\t\t%8.4f\t\t  %.4e\t\t  %.4e\t\t  %.4e\t\t  %.4e\t\t  %.4e\t\t%6.3f\t\t%6.3f\t\t%7.4f\t\t%8.3f\t\t%8.4f\t\t%8.4f \n',table(:,iSection));
                end
            end
        end
        
    end
    
    methods (Access=private)
        
        function output = getIncludedFile(~, files, name)
            for i = 1: length(files)
                if strcmpi(files{i}.Type, name)
                    output = files{i};
                    break
                end
            end
        end
    end
end

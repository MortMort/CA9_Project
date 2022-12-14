function ParamterUpdateinCSV(simulationpath,HWC,n)
%% Updaring the Parameter in the CSV file
% Inputs
% - SimulationPath
% - Hawc2 parameters

    for i=1:length(HWC.Parameter)
       if contains(HWC.Parameter{i,2},'Master')
           % do nothing
       else  
           CSVFile=fullfile(simulationpath,'INPUTS',HWC.Parameter{i,2});
           CSV = LAC.codec.CodecTXT(CSVFile);
           [txt line] = CSV.search(HWC.Parameter{i,1});
          temp_par_value=cell2mat(extractBetween(txt,'=',';'));
          % if controller parameter contains factors(*)
          if contains(temp_par_value,'*')
              temp_par_valuebefore=cell2mat(extractBefore(temp_par_value,'*'));
              temp_par_valueafter=cell2mat(extractAfter(temp_par_value,'*'));
              temp_par_value=[num2str(HWC.Parameter_Values(i,n)),'*',temp_par_valueafter];
          else
              temp_par_value=num2str(HWC.Parameter_Values(i,n));
          end
           CSV.replaceLine(line,strcat(extractBefore(txt,'='),'=',{' '},temp_par_value,'   ;%HWC Matlab updated'));
           CSV.save(CSVFile);
       end
    end
end
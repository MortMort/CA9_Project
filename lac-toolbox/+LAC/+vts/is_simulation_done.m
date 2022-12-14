function [status, cmdout] = is_simulation_done(simulation_folder,timeout,wait_time,onecheck)
% is_simulation_done checks if the simulations are ready and returns a status.
%
% syntax: [status, cmdout] = is_simulation_done(simulation_folder,timeout,wait_time,onecheck)
%
% INPUTS:
%   simulation_folder: path to the simulation folder
%   timeout: if simulations are not ready after 'timeout'[min], an error is
%   raised
%   wait_time: how often we check if simulations are ready?[min]
%   onecheck: check the simulation folder ones 1/0 (optional)
%
% OUTPUT:
%   status: status = 0 when all simulations are ready
%   cmdout: list of pending seeds
%
if nargin<4
    onecheck = 0;
end
% loop until .mas file is available (needed for status check)
while true
    % check if mas file was generated
    if ~isempty(dir(fullfile(simulation_folder,'Loads\INPUTS\','*.mas')))
        % find master file
        INPpath = fullfile(simulation_folder,'\Loads\INPUTS\');
        temp = dir(INPpath);
        for ii = 1:size(temp,1); if endsWith(temp(ii).name,'.mas'); break ; end; end;
        masFile = [INPpath temp(ii).name];
        break
    elseif onecheck
       status = 1;
       cmdout = 'master file not found';
       masFile = '';
        break
    end
    pause(3)
end



% loop until the simulations files are ready + timeout
if onecheck
    [status, cmdout] = system(['\\dkrkbfile01\flex\SOURCE\IsDistRunComplete ' masFile ' -checkall']);
    
    % display the status - e.g. missing .int files
    fprintf('\n')
    disp('Status:')
    fprintf('%s \n',cmdout)
else
    time = 0;
    status = 1;
    tic
    while ~(status==0)
        time = toc;
        pause(wait_time*60); %pause wait_time minutes
        
        
        
        % check folder; status = 0 when all simulations are ready
        [status, cmdout] = system(['\\dkrkbfile01\flex\SOURCE\IsDistRunComplete ' masFile ' -checkall']);
        
        
        
        if time > timeout*60
            error('Execution timed out. Simulations not ready. Please check the simulations setup.')
        end
        
        
        
        % display the status - e.g. missing .int files
        fprintf('\n')
        disp('Status:')
        fprintf('%s \n',cmdout)
        
        
        
    end
end
end

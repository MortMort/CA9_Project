function Solution = choose_turbines_glpk(data,tolerance,varargin)
    % Function to find the optimum choice of turbines to match a perfect
    % load envelope to a given % tolerance.
    %
    % Inputs:
    %   data         - m*n 2D array where m is the number of sensors, and n is the
    %                  number of turbines
    %   tolerance    - number between 0 - 1 indicating % deviation from envelope
    % 
    % Outputs:
    %   choices      - list of indices of selected turbines
    %   load_factors - calculated load factors for the chosen turbines
    %   num_feasible - number of feasible solutions for this many turbines
    %
    % Uses an open-source mex implementation of GNU GLPK
    % https://github.com/blegat/glpkmex
    % http://www.gnu.org/software/glpk/
    
    % GUI/cmd option (for solution interaction)
    p = inputParser;

    % GUI
    defaultOption = true;
    checkOptions = @(x) validateattributes(x,{'logical'},{'binary'});

    % unit test
    defaultInputTest = false;
    checkInputTest = @(x) validateattributes(x,{'logical'},{'binary'});

    addOptional(p,'option',defaultOption,checkOptions)
    addOptional(p,'testing',defaultInputTest,checkInputTest)

    parse(p,varargin{:})  
    useGUIinteraction = p.Results.option;
    applyUnitTest = p.Results.testing;

    % Find the perfect envelope of the loads
    envelope = get_envelope(data);
    % Find the allowable envelope using the tolerance
    allowable_envelope = envelope * (1 - tolerance);
    
    % Create a logical matrix that indicates which turbines are within
    % tolerance for each sensor
    choice_matrix = abs(data) >= allowable_envelope;
    lf_matrix=choice_matrix.*(envelope./abs(data));
    
    % Find simple properties of the problem
    num_turbines = size(choice_matrix,2);
    num_sensors  = size(choice_matrix,1);
    
    % Set up the linear programming problem
    c = ones(num_turbines,1);
    A = choice_matrix * -1;
    b = ones(num_sensors,1) * -1;
    lb = zeros(num_turbines,1);
    ub = ones(num_turbines,1);
    ctype = char(ones(1,num_sensors) * 'U');
    vtype = char(ones(1,num_turbines) * 'B');
    
    % Find an initial feasible solution
    [sol,optimum_number] = LAC.scripts.MasterModel.GNU.glpk(c,A,b,lb,ub,ctype,vtype);
    
    fprintf('Minimum number of turbines:\t  %3d\n',optimum_number);
    fprintf('Feasible solutions found:\t%5d',0); 
    
    % Create object to store all solutions
    feasible_solutions = {};
    n = 1;
    while sum(sol) == optimum_number   
        fprintf('\b\b\b\b\b');
        fprintf('%5d',n);
        % Save the current solution
        feasible_solutions{end+1} = sol;
        % Add constraints to prevent the current solution from being reused
        A(end+1,:) = sol';
        b(end+1,:) = optimum_number - 1;      
        ctype(end+1) = 'U';
        % Solve the new problem to find a new feasible solution
        sol = LAC.scripts.MasterModel.GNU.glpk(c,A,b,lb,ub,ctype,vtype);        
        % Count solutions
        n = n + 1;        
        % Stop searching
        if n > 1000
            fprintf('\n>1000 feasible solutions found, search will stop.');
            break;
        end        
    end
    
    % Calculate load factors for all feasible solutions
    feasible_solutions_load_factors = cellfun(@(fs) envelope ./ max(abs(data(:,logical(fs))),[],2),feasible_solutions,'Un',0);
    % Find the max load factor of each solution
    % The best solution is the one with the lowest max load factor
    [~,best_solution_idx] = min(cellfun(@(fslf) max(fslf),feasible_solutions_load_factors));
    % Output the best solution
    choices = find(feasible_solutions{best_solution_idx});
    load_factors = feasible_solutions_load_factors{best_solution_idx};
    num_feasible = n - 1;
   
    fprintf('\n\nProposed solution: \n'); 
    fprintf('ID (enumeration): %d\n',best_solution_idx);
    fprintf('Turbines: '); fprintf('%d ',choices);fprintf('\n');
    fprintf('Max. LF.: %.4f\n\n',max(load_factors));
    
    % handle to select solutions
    if useGUIinteraction
        Solution.feasible_solutions = feasible_solutions;
        Solution.feasible_solutions_load_factors = feasible_solutions_load_factors;
        Solution.lf_matrix_raw = lf_matrix;
    else            
        if n>1 && ~applyUnitTest
            prompt = 'Select other solution? y/n [n]: ';
            str = input(prompt,'s');  
        else
            str = 'n';
        end
    
        if lower(str) == 'y'
            items = cellfun(@(x) cellstr(join(string(find(x>0)),'-')), feasible_solutions);
            
            [answer,tf] = listdlg('PromptString',{'Select master models.',...
    'Only one combination can be selected.',''},...
    'SelectionMode','single','ListString',items);
    
                      if tf
                        choices = find(feasible_solutions{answer});
                        load_factors = feasible_solutions_load_factors{answer};
                      else
                          disp('No solution selected. Default used.')
                      end

            fprintf('\n\nCHOSEN SOLUTION \n');
            fprintf('ID (enumeration): %d\n',answer);
            fprintf('Turbines: '); fprintf('%d ',choices);fprintf('\n');
            fprintf('Max. LF.: %.4f\n\n',max(load_factors));
            
        elseif lower(str) == 'n'
            disp('Proposed solution is accepted.')
        else
            disp('Invalid answer. Proposed solution is accepted.')
        end
    end
    
    Solution.num_feasible=num_feasible;
    Solution.choices=choices;
    Solution.lf_best=load_factors;
    Solution.lf_matrix=lf_matrix(:,choices);      
end

function envelope = get_envelope(data)
    % This will get more complicated when load uncertainty factors are implemented
    envelope = max(abs(data),[],2);    
end
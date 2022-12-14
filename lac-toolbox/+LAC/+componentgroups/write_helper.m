function write_helper(Fid, object, variable_names, comment)
	% Loop through variable names.
	string = '';
	for ivariable_name=1:length(variable_names)
		variable_name = variable_names{ivariable_name};
        string = [string sprintf('%g', object.(variable_name)) ' '];
	end
	% Ensure minimum length (in order to try to make file a bit more readable).
	nblanks = 50;
	if length(string) < nblanks
		blank_string = blanks(nblanks - length(string));
		string = [string blank_string comment];
	end
	fprintf(Fid, '%s', string);
	fprintf(Fid, '\n');
end
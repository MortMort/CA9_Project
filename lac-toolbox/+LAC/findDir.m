function all_dir = findDir(folderPath)
    %% find all folders to search for files in
    all_struct = dir(folderPath);
    all_dir= all_struct([all_struct(:).isdir]);
    all_dir = {all_dir.name};
end
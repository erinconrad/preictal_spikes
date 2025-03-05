%% grab sz annotations

%% Patient id
first_row = 6799;

%% paths
addpath('../../tools/');
paths = preictal_paths;

%% patient list
patient_list = '../../data/deid_with_redcap.csv';
out_path = '../../data/sz_anns.csv';

%% Load it
T = readtable(patient_list);

out_var =  {'Patient', 'IEEGname','annotation_time','annotation','file_duration','prior_file','prior_file_duration','next_file'};
%% Load the out_path
if exist(out_path,'file') ~= 0
    szT = readtable(out_path);
    last_emu_filename = szT.IEEGname{end};
    row = find(strcmp(T.ieeg_file_name,last_emu_filename));
    start_row = row + 1;
else
    % Prep annotation table
    
    szT = table('Size', [0 8], 'VariableTypes', ...
        {'double', 'cell','double','cell','double','cell','double','cell',}, 'VariableNames', ...
       out_var);
    start_row = first_row;
end

fprintf('\nStarting with row %d\n',start_row);


for i = start_row:size(T,1)

    patient_id = T.patient_id(i);
    filename = T.ieeg_file_name{i};

    % Get all annotations and file dur
    aT = grab_annotations_andfiledur(filename,paths.ieeg_folder,...
        paths.ieeg_pw_file,paths.ieeg_login);
    

    if isempty(aT)
        fprintf(['\nPatient %d %s failed \n'],patient_id,filename);
        continue
    end


    %% Get the next file name

    % get the day of the file
    pattern = '(?<=_Day)(\d{2})(?=_)';
    tokens = regexp(filename, pattern, 'tokens');
    day = str2double(tokens{1}(1));
    next_day = day + 1;
    prior_day = day - 1;

    % get the first part of the filename
    C = strsplit(filename,'_');
    adm_id = C{1};

     % get the file name for the next day
    if next_day < 10
        next_file = sprintf('%s_Day0%d_1',adm_id,next_day);
    else
        next_file = sprintf('%s_Day%d_1',adm_id,next_day);
    end

    if prior_day < 10
        prior_file = sprintf('%s_Day0%d_1',adm_id,prior_day);
    else
        prior_file = sprintf('%s_Day%d_1',adm_id,prior_day);
    end

    % see if the files exist
    nextT = grab_annotations_andfiledur(next_file,paths.ieeg_folder,...
        paths.ieeg_pw_file,paths.ieeg_login);
    if isempty(nextT)
        next_filename = {''};
    else
        next_filename = {next_file};
    end

    priorT = grab_annotations_andfiledur(prior_file,paths.ieeg_folder,...
        paths.ieeg_pw_file,paths.ieeg_login);
    if isempty(priorT)
        prior_filename = {''};
        prior_file_duration = nan;
    else
        prior_filename = {prior_file};
        prior_file_duration = priorT.file_duration(1);
    end
    

    %% Mine for seizure-y annotations
    sz_annotations = contains(aT.annotations,["seizure","sz","onset","UEO","EEC"],'IgnoreCase',true);
    szT_curr = aT(sz_annotations,:);

    % remove persyst
    szT_curr(contains(szT_curr.annotations,'Persyst'),:) = [];

    nsz = size(szT_curr,1);
    if nsz ~=0
        szT = [szT;table(repmat(patient_id,nsz,1),...
            cellstr(repmat(filename,nsz,1)),...
            szT_curr.annotation_times,...
            szT_curr.annotations,...
            szT_curr.file_duration,...
            repmat(prior_filename,nsz,1),...
            repmat(prior_file_duration,nsz,1),...
            repmat(next_filename,nsz,1),...
            'VariableNames',out_var)];
        
    end


    writetable(szT,out_path);

end


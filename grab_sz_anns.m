%% grab sz annotations

%% Patient id
first_row = 6799;

%% paths
addpath('../tools/');
paths = preictal_paths;

%% patient list
patient_list = '../data/deid_with_redcap.csv';
out_path = '../data/sz_anns.csv';

%% Load it
T = readtable(patient_list);

out_var =  {'Patient', 'IEEGname','annotation_time','annotation','file_duration'};
%% Load the out_path
if exist(out_path,'file') ~= 0
    szT = readtable(out_path);
    last_emu_filename = szT.IEEGname{end};
    row = find(strcmp(T.ieeg_file_name,last_emu_filename));
    start_row = row + 1;
else
    % Prep annotation table
    
    szT = table('Size', [0 5], 'VariableTypes', ...
        {'double', 'cell','double','cell','double'}, 'VariableNames', ...
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

    %% Mine for seizure-y annotations
    sz_annotations = contains(aT.annotations,["seizure","sz","onset","UEO","EEC"],'IgnoreCase',true);
    szT_curr = aT(sz_annotations,:);

    % remove persyst
    szT_curr(contains(szT_curr.annotations,'Persyst'),:) = [];

    nsz = size(szT_curr,1);
    if nsz == 0, continue; end
    szT = [szT;table(repmat(patient_id,nsz,1),...
        cellstr(repmat(filename,nsz,1)),...
        szT_curr.annotation_times,...
        szT_curr.annotations,...
        szT_curr.file_duration,...
        'VariableNames',out_var)];


    writetable(szT,out_path);

end


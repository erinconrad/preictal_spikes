%% find_isolated_szs

%{
Ways to improve
- maybe remove annotations that include the text "no"

%}

%% Parameters
ignore_time = 60*10; % 10 minutes
cluster_time = 60*60*6; % 6 hours


%% paths
addpath('../../tools/');
paths = preictal_paths;

%% patient list
patient_list = '../../data/deid_with_redcap.csv';
sz_ann_path = '../../data/sz_anns.csv';
out_path = '../../data/isolated_szs.csv';

%% Load the pt list
pT = readtable(patient_list);

%% Load the sz_anns
T = readtable(sz_ann_path);
nszs = size(T,1);
isolated = nan(nszs,1);

%% Decide what to call a definitive sz
% An annotation of eec or ueo
def_sz = contains(T.annotation,["eec","ueo"],"IgnoreCase",true);

%% Do logic to decide if it's isolated
% Note that this might result in multiple annotations for the same sz if
% both eec and ueo present, will need to reduce in the end

% Loop over szs
for i = 1:nszs

    % skip if not definite sz
    if def_sz(i) == 0, continue; end

    % get the time and file
    sz_time = T.annotation_time(i);
    file = T.IEEGname{i};
    duration = T.file_duration(i);
    prior_file = T.prior_file{i};
    prior_file_duration = T.prior_file_duration(i);

    % get the day of the file
    pattern = '(?<=_Day)(\d{2})(?=_)';
    tokens = regexp(file, pattern, 'tokens');
    day = str2double(tokens{1}(1));

    % get the first part of the filename
    C = strsplit(file,'_');
    adm_id = C{1};

    %% Look for szs in the preceding 6 hours
    % see if there are annotations matching possible szs >10 minutes before
    % AND less than 6 hours before
    same_file_rows = T(strcmp(T.IEEGname,file),:);
    another_sz = any((sz_time - same_file_rows.annotation_time) > ignore_time & ...
        (sz_time - same_file_rows.annotation_time) < cluster_time);

    if another_sz == 1
        isolated(i) = 0;
        continue % don't need to do other checks
    end

    % If the sz time is more than 6 hours after the start of the file and
    % no seizures with in the past 6 hours, it's isolated
    if sz_time > cluster_time 
        isolated(i) = 1;
        continue
    end

    % If sz close to beginning of file, need to check prior file to see if
    % sz within 6 hours
    if sz_time < cluster_time
        if day == 1
            isolated(i) = 0; % if first file, can't say it's isolated
            continue
        else
            
            % get rows for prior day
            prior_day_rows = T(strcmp(T.IEEGname,prior_file),:);
            if isempty(prior_day_rows)
                if sum(strcmp(pT.ieeg_file_name,prior_file)) > 0
                    % ok if there's a file in main list
                    isolated(i) = 1;
                    continue
                else
                    % if no file at all, can't say it's isolated
                    isolated(i) = 0; 
                    continue
                end
            end

            if ~isempty(prior_day_rows)
                % Get the duration of the prior file
                assert(prior_file_duration == prior_day_rows.file_duration(1))
    
                % Add this duration to the sz_time to get the time in the same
                % scale as the time of the last file - e.g., if a time in prior
                % file is 20, and duration 24, and sz_time is 3, the
                % sz_time_rel will be 27, indicating it's 7 hours after the
                % time of interest in the prior file
                sz_time_rel = sz_time + prior_file_duration;
    
                % do same time check
                another_sz = any((sz_time_rel - prior_day_rows.annotation_time) > ignore_time & ...
                    (sz_time_rel - prior_day_rows.annotation_time) < cluster_time);
                if another_sz == 1
                    isolated(i) = 0;
                    continue
                end

            end
        end
    end

    % If I've made it to here, then no clustered sz in the current file or preceding file
    isolated(i) = 1;


end

T.isolated = isolated;

%% Now, remove any duplicate so I really only have one per sz
for i = 1:nszs
    
    if isolated(i) == 1
        sz_time = T.annotation_time(i);
        file = T.IEEGname{i};
        % Look for other rows within 10 minutes where this is also 1
        close_and_isolated = abs(T.annotation_time - sz_time) < ignore_time & T.isolated == 1 & strcmp(T.IEEGname,file);
        close_and_isolated(i) = 0;

        T.isolated(close_and_isolated) = 0;

    end


end

%% Details
isolated_szs = T(T.isolated == 1,:);
npts = length(unique(isolated_szs.Patient));
fprintf('\nThere are %d unique patients and %d lead seizures.\n',npts,nansum(T.isolated));

%% Save the output
writetable(T,out_path)
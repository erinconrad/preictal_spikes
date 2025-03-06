%% turn_probs_to_counts

%% Parameters
prob_thresh = 0.9;

%% Paths
spike_prob_path = '../../spike_probs/';
eeg_data_path = '../../eeg_data/';
spike_detections_path = '../../spike_detections/';

if ~exist(spike_detections_path,"dir"), mkdir(spike_detections_path); end

% Loop over spike prob directories
listing = dir(spike_prob_path);
for i = 1:length(listing)

    % Skip if not an expected name
    if ~contains(listing(i).name,'sz') || strcmp(listing(i).name(1),'.')
        continue;
    end

    % load the meta file
    meta = load([eeg_data_path,listing(i).name,'/meta.mat']);
    meta = meta.meta;
    chunk_dur = 600;

    detections = meta;
    detections.detections = cell(length(meta.chunk_files),1);
    detections.all_detections = [];
    detections.detection_files = {};

    sub_detection_path = [spike_detections_path,listing(i).name,'/'];
    if ~exist(sub_detection_path,"dir"), mkdir(sub_detection_path); end

    % get the full path
    curr_eeg_path = [listing(i).folder,'/',listing(i).name,'/'];
    sublisting = dir(curr_eeg_path);
    for j = 1:length(sublisting)
        if ~contains(sublisting(j).name,'.csv')
            continue;
        end

        %% Load the csv
        T = readtable([curr_eeg_path,sublisting(j).name]);
        probs = T.Var1;
        times = linspace(0,chunk_dur,length(probs));

        %% Get the times above thresh
        above_thresh = probs > prob_thresh;

        %% Get just isolated spikes wihtin 1 second
        % Assume above_thresh is nsamples x 1 and times is nsamples x 1
        % Create a new array initialized to 0s
        above_thresh_new = zeros(size(above_thresh));
        
        % Find indices where above_thresh is 1
        idx = find(above_thresh == 1);
        
        if ~isempty(idx)
            % Initialize group start index (within idx)
            groupStart = 1;
            % Loop over indices in the idx array (starting at the second element)
            for k = 2:length(idx)
                % If the time difference between the current event and previous event is more than 1 sec,
                % we treat it as a boundary between groups.
                if times(idx(k)) - times(idx(k-1)) > 1
                    % Process the group from groupStart to i-1
                    groupIdx = idx(groupStart:k-1);
                    % Select the middle index of the group.
                    % For even number of events, round will pick one near the middle.
                    midIdx = groupIdx(round(length(groupIdx)/2));
                    above_thresh_new(midIdx) = 1;
                    
                    % Reset group start to current index i
                    groupStart = k;
                end
            end
            % Process the last group (from groupStart to end of idx)
            groupIdx = idx(groupStart:end);
            midIdx = groupIdx(round(length(groupIdx)/2));
            above_thresh_new(midIdx) = 1;
        end
        above_thresh_new = logical(above_thresh_new);

        %% Output detections
        detections.detections{j} = times(above_thresh_new);
        % Calculate number of detections from the logical index.
        ndetections = sum(above_thresh_new);
        
        % Append detection times as a column vector.
        detections.all_detections = [detections.all_detections; times(above_thresh_new)' + meta.chunk_times(j,1)];
        
        % Append file names as a cell array of strings to match the number of detections.
        detections.detection_files = [detections.detection_files; repmat({meta.chunk_files{j}}, ndetections, 1)];
    end

    %% Save detections
    save([sub_detection_path,'detections.mat'],'detections')
    
end
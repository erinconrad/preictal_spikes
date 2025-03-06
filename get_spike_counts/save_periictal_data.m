%% save peri=ictal data
% SHOULD I ADD A NEGATIVE OFFSET TO THE SZ TIME OF ONE MINUTE SO THAT THE
% ONE MINUTE PREICTAL PERIOD IS IN THE SZ WINDOW???

% need to accoun for non finite things in filtfilt

%% Parameters
duration = 6*3600; % 6 hours
chunk_size = 10*60; % 10 minutes
nchunks = duration*2/chunk_size;

%% Paths
sz_path = '../../data/isolated_szs.csv';
eeg_path = '../../eeg_data/';
addpath('../../tools/');
paths = preictal_paths;
addpath(genpath(paths.ieeg_folder));
addpath(genpath('../'))

if ~exist("eeg_path","dir")
    mkdir(eeg_path)
end

%% Grab the isolated szs
T = readtable(sz_path);
T = T(T.isolated==1,:);
nszs = size(T,1);

% Loop over the szs
for i = 1:nszs

    %% Get data about the sz
    sz_time = T.annotation_time(i);
    ieeg_file = T.IEEGname{i};
    patient = T.Patient(i);
    file_duration = T.file_duration(i);
    prior_file = T.prior_file{i};
    next_file = T.next_file{i};
    prior_file_duration = T.prior_file_duration(i);

    %% Determine the times and files over which to run ieeg.org
    % initialize
    chunk_times = nan(nchunks,2);
    chunk_files = cell(nchunks,1);

    % fill these up with values
    for j = 1:nchunks
        chunk_start_unadjusted = sz_time - chunk_size * nchunks/2 + (j-1) * chunk_size;
        chunk_end_unadjusted = chunk_start_unadjusted + chunk_size;

        % adjust for file duration
        if chunk_start_unadjusted < 0
            if chunk_end_unadjusted > 0
                chunk_times(j,:) = [nan nan]; % ignore chunks that cross files
                chunk_files{j} = '';
            else
                chunk_start_adjusted = chunk_start_unadjusted + prior_file_duration;
                chunk_end_adjusted = chunk_end_unadjusted + prior_file_duration;
                chunk_times(j,:) = [chunk_start_adjusted chunk_end_adjusted];
                chunk_files{j} = prior_file;
            end
        elseif chunk_end_unadjusted > file_duration
            if chunk_start_unadjusted < file_duration
                chunk_times(j,:) = [nan nan]; % ignore chunks that cross files
                chunk_files{j} = '';
            else
                chunk_start_adjusted = chunk_start_unadjusted - file_duration;
                chunk_end_adjusted = chunk_end_unadjusted - file_duration;
                chunk_times(j,:) = [chunk_start_adjusted chunk_end_adjusted];
                chunk_files{j} = next_file;

            end

        else
            chunk_times(j,:) = [chunk_start_unadjusted chunk_end_unadjusted];
            chunk_files{j} = ieeg_file;
        end
    end
    
    % Loop over chunks
    for j = 1:nchunks
        
        %% prep for download
        curr_times = chunk_times(j,:);
        curr_file = chunk_files{j};

        %% do the download
        [data,fs,chLabels] = pull_ieeg_data(curr_file,paths.ieeg_pw_file,paths.ieeg_login,curr_times);

        
        if isempty(data)
            fprintf('\nNo data for sz %d chunk %d\n',i,j);
            continue
        end

        %% Downsample and filter
        % Downsample the data to 128 Hz
        if fs == 256
            data = resample(data, 1, 2);
        else
            error('surprising fs');
        end

        % Specify the notch frequency 
        notchFreq = 60;  
        
        % Compute the normalized frequency (half the sampling rate is the Nyquist frequency)
        wo = notchFreq/(fs/2);  
        
        % Choose a quality factor Q (adjust as needed; higher Q means a narrower notch)
        Q = 35;  
        bw = wo/Q;
        
        % Design the notch filter using the IIR notch design
        [b_notch, a_notch] = iirnotch(wo, bw);
        
        % Apply the notch filter using zero-phase filtering to avoid phase distortion
        data(isnan(data)) = 0;
        data_notched = filtfilt(b_notch, a_notch, data);

        % Design a 4th order IIR high-pass filter using the designfilt function
        hpFilt = designfilt('highpassiir', 'FilterOrder', 4, ...
                            'HalfPowerFrequency', 0.5, 'SampleRate', fs);
        
        % Apply the high-pass filter with zero-phase filtering
        data_filtered = filtfilt(hpFilt, data_notched);
        nsamples = size(data_filtered,1);
        

        %% Get the right channels
        allChannels = chLabels;
        desiredChannels = {'Fp1', 'F3', 'C3', 'P3', 'F7', 'T3', 'T5', 'O1', ...
                   'Fz', 'Cz', 'Pz', 'Fp2', 'F4', 'C4', 'P4', 'F8', ...
                   'T4', 'T6', 'O2', 'EKG'};

        % Preallocate an array for storing indices of matching channels.
        % The indices will correspond to positions in the allChannels cell array.
        channelIndices = nan(size(desiredChannels));
        nchs = length(desiredChannels);
        
        for k = 1:length(desiredChannels)
            if strcmpi(desiredChannels{i}, 'EKG')
                % For the EKG channel, use a regex that matches any label starting with
                % 'EKG' or 'ECG' (case insensitive).
                ekgMatch = find(~cellfun(@isempty, regexp(allChannels, '^(ekg|ecg)', 'ignorecase')));
                if ~isempty(ekgMatch)
                    channelIndices(k) = ekgMatch(1);  % Pick the first match if multiple are found.
                end
            else
                % For all other channels, do a case-insensitive exact match.
                match = find(strcmpi(allChannels, desiredChannels{k}));
                if ~isempty(match)
                    channelIndices(k) = match(1);  % In case of duplicates, pick the first.
                end
            end
        end

        %% Fill up the right data
        ordered_data = zeros(nchs,nsamples);
        for k = 1:nchs
            index = channelIndices(k);
            if isnan(index), continue; end
            ordered_data(k,:) = data_filtered(:,index);
        end

        %% Prep the output
        channels = desiredChannels;
        data = ordered_data;
        Fs = 128;
        

        % output file name
        subdir = [eeg_path,sprintf('sz_%d/',i)];
        if ~exist(subdir,"dir"), mkdir(subdir); end
        out_file = [subdir,sprintf('chunk_%d.mat',j)];

        %% save it
        save(out_file,"channels","data","Fs","patient","ieeg_file","sz_time",...
            "curr_times","curr_file","chunk_times","chunk_files");
        


    end



end
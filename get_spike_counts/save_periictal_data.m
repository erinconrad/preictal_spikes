%% save peri=ictal data

%% Parameters
duration = 6*3600; % 6 hours
chunk_size = 10*60; % 10 minutes
nchunks = duration*2/chunk_size;

%% Paths
sz_path = '../../data/isolated_szs.csv';
eeg_path = '../../eeg_data/';
addpath('../../tools/');
paths = preictal_paths;

if ~exist("eeg_path","folder")
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

    %% Determine the times and files over which to run ieeg.org
    % initialize
    chunk_times = nan(nchunks,2);
    chunk_files = cell(nchunks,1);

    % fill these up with values that ignore the file duration


end
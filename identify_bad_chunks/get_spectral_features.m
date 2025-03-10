%% get_spectral_features

%% Parameters
% Define frequency bands for EEG
deltaBand   = [1 4];    % Delta: 1-4 Hz
thetaBand   = [4 8];    % Theta: 4-8 Hz
alphaBand   = [8 13];   % Alpha: 8-13 Hz
betaBand    = [13 30];  % Beta: 13-30 Hz
gammaBand   = [30 50];  % Gamma: 30-50 Hz
broadbandRange = [1 50];
sixtyHzBand = [57 63];

if ~exist("start_sz","var")
    error('list start sz');
end

if ~exist("end_sz","var")
    error('please specify end_sz');
end

%% Paths
eeg_dir = '/mnt/sauce/littlab/users/erinconr/projects/preictal_spikes/eeg_data/';
out_dir = '/mnt/sauce/littlab/users/erinconr/projects/preictal_spikes/spectral_data/';

if ~exist(out_dir,'dir'), mkdir(out_dir); end

%% Main
% Loop over eeg subdirs
listing = dir(eeg_dir);
for i = 1:length(listing)

    % Skip if not an expected name
    if ~contains(listing(i).name,'sz') || strcmp(listing(i).name(1),'.')
        continue;
    end
    
    numStr = regexp(listing(i).name,'\d+','match');
    if str2num(numStr{1})<start_sz, continue; end
    if str2num(numStr{1})>end_sz, continue; end

    % get the full path
    curr_eeg_path = [listing(i).folder,'/',listing(i).name,'/'];

    % Look for and delete files within the eeg path that start with '._'. These will
    % screw up spike net
    sublisting = dir(curr_eeg_path);
    for j = 1:length(sublisting)
        if startsWith(sublisting(j).name,'.') && contains(sublisting(j).name,'mat')
            delete([curr_eeg_path,sublisting(j).name]);
        end
    
    end


    % Make output path
    curr_output_dir = [out_dir,listing(i).name,'/'];
    if ~exist(curr_output_dir,"dir"), mkdir(curr_output_dir); end

    % Loop over chunks
    for j = 1:72
        chunk_file = [curr_eeg_path,sprintf('chunk_%d.mat',j)];
        if ~exist(chunk_file,"file"), continue; end

        %% Load the file
        load(chunk_file);

        %% Convert to bipolar I guess
        [bipolar_values,bipolar_labels] = scalp_bipolar(channels,data');


        %% Compute power in each band for every channel
        bp_broadband = bandpower(bipolar_values, Fs, broadbandRange);
        bp_delta     = bandpower(bipolar_values, Fs, deltaBand);
        bp_theta     = bandpower(bipolar_values, Fs, thetaBand);
        bp_alpha     = bandpower(bipolar_values, Fs, alphaBand);
        bp_beta      = bandpower(bipolar_values, Fs, betaBand);
        bp_gamma     = bandpower(bipolar_values, Fs, gammaBand);
        bp_sixty     = bandpower(bipolar_values, Fs, sixtyHzBand);

        %% Save this
        save([curr_output_dir,sprintf('chunk_%d.mat',j)],...
            "bp_broadband","bp_delta","bp_theta","bp_alpha",...
            "bp_beta","bp_gamma","bp_sixty");


    end

end
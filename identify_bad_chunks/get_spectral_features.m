%% get_spectral_features

%% Parameters
winDuration = 10; 

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

    fprintf('\nDoing seizure %d\n',i);
    
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

        %% Make nans zeros
        bipolar_values(isnan(bipolar_values)) = 0;
        winSamples = winDuration * Fs; 

        [nSamples, nChannels] = size(bipolar_values);
        nWins = floor(nSamples / winSamples);  % number of full windows
        
        % Preallocate arrays to hold bandpower values for each channel and window
        bp_broadband = nan(nWins, nChannels);
        bp_delta     = nan(nWins, nChannels);
        bp_theta     = nan(nWins, nChannels);
        bp_alpha     = nan(nWins, nChannels);
        bp_beta      = nan(nWins, nChannels);
        bp_gamma     = nan(nWins, nChannels);
        bp_sixty     = nan(nWins, nChannels);
        
        % Process each channel and window
        for ch = 1:nChannels
            
            if strcmp(bipolar_labels{ch},'-') || contains(bipolar_labels{ch},'EKG')
                continue
            end

            for win = 1:nWins
                % Determine sample indices for this window
                idxStart = (win-1)*winSamples + 1;
                idxEnd = win * winSamples;
                segment = bipolar_values(idxStart:idxEnd, ch);
                
                % Calculate bandpower for each frequency band
                bp_broadband(win, ch) = bandpower(segment, fs, broadbandRange);
                bp_delta(win, ch)     = bandpower(segment, fs, deltaBand);
                bp_theta(win, ch)     = bandpower(segment, fs, thetaBand);
                bp_alpha(win, ch)     = bandpower(segment, fs, alphaBand);
                bp_beta(win, ch)      = bandpower(segment, fs, betaBand);
                bp_gamma(win, ch)     = bandpower(segment, fs, gammaBand);
                bp_sixty(win, ch)     = bandpower(segment, fs, sixtyHzBand);
            end
        end
        
        % Compute the median bandpower over all windows for each channel
        median_broadband = median(bp_broadband, 1, 'omitnan');
        median_delta     = median(bp_delta, 1, 'omitnan');
        median_theta     = median(bp_theta, 1, 'omitnan');
        median_alpha     = median(bp_alpha, 1, 'omitnan');
        median_beta      = median(bp_beta, 1, 'omitnan');
        median_gamma     = median(bp_gamma, 1, 'omitnan');
        median_sixty     = median(bp_sixty, 1, 'omitnan');


        %% Save this
        save([curr_output_dir,sprintf('chunk_%d.mat',j)],...
            "median_broadband","median_delta","median_theta","median_alpha",...
            "median_beta","median_gamma","median_sixty","bipolar_labels","curr_file",...
            "curr_times");


    end

end
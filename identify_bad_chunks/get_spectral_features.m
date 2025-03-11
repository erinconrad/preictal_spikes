%% get_spectral_features

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
for i = start_sz:end_sz

    
    fprintf('\nDoing seizure %d\n',i);
    
    

    % get the full path
    curr_eeg_path = [eeg_dir,sprintf('sz_%d',i),'/'];
    if ~exist(curr_eeg_path,"dir"), continue; end

    % Look for and delete files within the eeg path that start with '._'. These will
    % screw up spike net
    sublisting = dir(curr_eeg_path);
    for j = 1:length(sublisting)
        if startsWith(sublisting(j).name,'.') && contains(sublisting(j).name,'mat')
            delete([curr_eeg_path,sublisting(j).name]);
        end
    
    end


    % Make output path
    curr_output_dir = [out_dir,sprintf('sz_%d',i),'/'];
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
        
        %% Compute frequency-specific bandpowers
        bp = computeEEGBandPowers(bipolar_values, Fs);

        %% Save this
        save([curr_output_dir,sprintf('chunk_%d.mat',j)],...
            "bp","bipolar_labels","curr_file",...
            "curr_times");


    end

end
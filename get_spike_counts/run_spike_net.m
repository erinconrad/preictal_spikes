%% Goal
%{
Here I will loop over a bunch of directories representing different
seizures, each directory containing mat files corresponding to 10 minute
chunks of eeg data surrounding the seizure. For each directory, I will run
spike net, thus outputting spike probabilities in a separate directory

%}

%% Paths
spikenet2_env = '/mnt/sauce/littlab/users/erinconr/conda_env/spikenet2';
spikenet2_script_path = '/mnt/sauce/littlab/users/erinconr/utilities/SN2R11_demo_20240715/run_sn2r11.py';
eeg_dir = '/mnt/sauce/littlab/users/erinconr/projects/preictal_spikes/eeg_data/';
spike_prob_dir = '/mnt/sauce/littlab/users/erinconr/projects/preictal_spikes/spike_probs/';

%% Activate conda environment
system(sprintf('conda activate %s',spikenet2_env));


% Loop over eeg subdirs
listing = dir(eeg_dir);
for i = 1:length(listing)

    % Skip if not an expected name
    if ~contains(listing(i).name,'sz')
        continue;
    end

    % get the full path
    curr_eeg_path = [listing(i).folder,listing(i).name,'/'];

    % Make output path
    curr_prob_path = [spike_prob_dir,listing(i).name,'/'];

    fprintf('\nRunning spike net for %s\n',listing(i).name);

    %% Run spike net
    system(sprintf('python %s %s %s',spikenet2_script_path,curr_eeg_path,curr_prob_path));

    

end


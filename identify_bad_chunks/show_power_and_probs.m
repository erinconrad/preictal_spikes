%% show probs and power

%% stitch_probs
prob_thresh = 0.5;
plot_mean = 1;
chunk_dur = 10*60;
nchunks = 72;
sz_chunk = 37;
npoints = 9585;


%% Paths
spike_prob_path = '../../spike_probs/';
spectral_path = '../../spectral_data/';

%% Sub-paths
curr_prob_path = [spike_prob_path,sprintf('sz_%d',which_sz),'/'];
curr_spectral_path = [spectral_path,sprintf('sz_%d',which_sz),'/'];

%% Initialize stuff
times = linspace(0,nchunks*chunk_dur,nchunks);
transitions = nan(nchunks,1);
mean_probs = nan(nchunks,1);
all_bp = nan(nchunks,1);

% Loop over the probs
for i = 1:nchunks

    curr_transitions = 0;
    if i == sz_chunk-1
        curr_transitions(end) = 2;
    else
        curr_transitions(end) = 1;
    end
    transitions(i,1) = curr_transitions;

    if ~exist([curr_prob_path,sprintf('chunk_%d_sn2r11.csv',i)],"file")
        continue;
    end

    % Load the prob
    T = readtable([curr_prob_path,sprintf('chunk_%d_sn2r11.csv',i)]);

    % convert to array
    a = table2array(T);
    mean_probs(i,1) = sum(a>prob_thresh);


    % load the BP
    if ~exist([curr_spectral_path,sprintf('chunk_%d.mat',i)],"file")
        continue
    end
    load([curr_spectral_path,sprintf('chunk_%d.mat',i)]);

    bp_of_interest = median_sixty;
    mean_bp = mean(bp_of_interest(~strcmp(bipolar_labels,'-') & ...
        ~contains(bipolar_labels,'EKG')));
    all_bp(i,1) = mean_bp;


end
times = times/3600;


figure
set(gcf,'Position',[1 1 1400 1000])
tiledlayout(2,1)
nexttile
plot(mean_probs,'LineWidth',2);
ylabel('Probs')
hold on
%
for i = 1:length(transitions)
    if transitions(i) == 1
        plot([i i],ylim,'k--');
    end
    if transitions(i) == 2
        plot([i i],ylim,'r--','LineWidth',2);
    end

end
%


nexttile
plot(all_bp,'LineWidth',2);
ylabel('Power')
%{
hold on
for i = 1:length(transitions)
    if transitions(i) == 1
        plot([times(i) times(i)],ylim,'k--');
    end
    if transitions(i) == 2
        plot([times(i) times(i)],ylim,'r--','LineWidth',2);
    end

end
%}



fprintf('\nplotting sz %d\n',which_sz);
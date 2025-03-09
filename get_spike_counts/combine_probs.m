%% combine_probs

%% Parameters
prob_thresh = 0.9;
chunk_dur = 10*60;
nchunks = 72;
sz_chunk = 37;
npoints = 9585;
nszs = 116;

%% Paths
spike_prob_path = '../../spike_probs/';

%% Initialize counts
counts = nan(nszs,nchunks);
times = linspace(0,nchunks*chunk_dur,npoints*nchunks)/3600;
transitions = nan(npoints*nchunks,1);

%% Fill transitions
for j = 1:nchunks
    curr_transitions = zeros(npoints,1);
    if j == sz_chunk-1
        curr_transitions(end) = 2;
    else
        curr_transitions(end) = 1;
    end
    transitions((j-1)*npoints+1:j*npoints,1) = curr_transitions;
end

%% Fill counts
% Loop over szs
for i = 1:nszs

    % Path to the spike probs
    curr_prob_path = [spike_prob_path,sprintf('sz_%d',i),'/'];
    if ~exist(curr_prob_path,"dir")
        fprintf('\ncan''t find sz %d\n',i);
        continue;
    end

    % Loop over chunks
    for j = 1:nchunks
        
        if ~exist([curr_prob_path,sprintf('chunk_%d_sn2r11.csv',j)],"file")
            fprintf('\ncan''t find sz %d chunk %d\n',i,j);
            continue;
        end
        
        % Load the prob
        T = readtable([curr_prob_path,sprintf('chunk_%d_sn2r11.csv',j)]);

        % convert to array
        a = table2array(T);
        counts(i,(j-1)*npoints+1:j*npoints,1) = sum(a>prob_thresh);

    end

end


%% plot it
%{
figure
set(gcf,'Position',[1 1 1400 1000])
plot(times,nanmean(counts,1),'LineWidth',2);
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

%% Paired plot comparing pre and post
pre = nanmean(counts(:,1:36),2);
post = nanmean(counts(:,38:end),2); % exclude sz one (37)
x = pre;
y = post;
figure

scatter(x, y, 'filled');
hold on;

% Determine plot limits for the unity line
allVals = [x; y];
minVal = min(allVals);
maxVal = max(allVals);

% Plot the dotted unity line (y = x)
plot([minVal, maxVal], [minVal, maxVal], 'k--', 'LineWidth', 1.5);

% Perform the Wilcoxon signed rank test
[p, ~, ~] = signrank(x, y);

% Create a text annotation for the p-value
txt = sprintf('p = %.3f', p);
% Choose a location: here, 5% from the left and 10% from the top of the current axis
ax = gca;
xPos = ax.XLim(1) + 0.05*range(ax.XLim);
yPos = ax.YLim(2) - 0.10*range(ax.YLim);
text(xPos, yPos, txt, 'FontSize', 12, 'Color', 'r');

% Label axes and add title
xlabel('Pre');
ylabel('Post');

fprintf('\n%1.1f%% of non-nan post-pre are positive\n',...
    sum(post-pre>0)/sum(~isnan(post-pre))*100)
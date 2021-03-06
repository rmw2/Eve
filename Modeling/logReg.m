%Perform logistic regression a la DePace

%Gap is a structure that contains the profiles of the gap genes over time,
%with some given temporal resolution
%miniCP is a mini Compiled Particles structure generated by cpStreamline()
%startTime and endTime specify the time in minutes of nc14 at which the
%model will be trained.  ideally endTime - startTime = Gap.timeStep

function [coeffs, activeNucleiModel,h] = ...
    logReg(Gap, miniCP, startTime)


%TODO - separate by stripe enhancers

if ~isfield(Gap, 'avgExp')
    error('Gap structure incomplete: Run gapGeneTimeTrace() first')
end

%Gap gene protein data:
endTime = startTime + Gap.timeStep;
gapFrame = find(0:Gap.timeStep:60 <= startTime,1,'last');
xTraining = squeeze(Gap.avgExp(gapFrame,:,:));

%Extract indices in training data set corresponding to times
time = miniCP.ElapsedTime-miniCP.ElapsedTime(1);
trainingRange = find(time >= startTime, 1):...
    find(time < endTime, 1, 'last');

%Tile to match size of y input
xTraining = repmat(xTraining,length(trainingRange),1);


%Eve expression data:
%needs to be in logical form
nP = miniCP.activeNuclei(trainingRange,:,3)';
nP = nP(:);
nN = miniCP.totalNuclei(trainingRange,:,2)';
nN = nN(:);

yTraining = [nP,nN];

%Filter out zero points
filter = (yTraining(:,2) ~= 0) & (yTraining(:,1)<=yTraining(:,2));

%DO FIT--------------------------------------------------------------------
coeffs = glmfit(xTraining(filter,:), yTraining(filter,:), 'Binomial');
nParameters = length(coeffs);
%--------------------------------------------------------------------------

%Now plot timetrace of eve using fit
%Create the timetrace
dims = size(Gap.avgExp);
activeNucleiModel = zeros(dims(1:2));


for t = 1:dims(1)
    eta = coeffs(1);
    for j = 1:nParameters-1
        eta = eta + coeffs(j+1) * Gap.avgExp(t,:,j);
    end
    activeNucleiModel(t,:) = 1 ./ (1 + exp(-eta));
end

%plot heatmaps of relevant inputs, reference time-trace, and model
modelRange = 1:find(time > 60,1);
if isempty(modelRange)
    modelRange = 1:length(miniCP.activeNuclei(:,1,1));
end
%KLUGE for activeNuclei > 1 problem
%miniCP.activeNuclei(miniCP.activeNuclei(:,:,1) > 1) = 1;

%Plot gap gene protein concentrations
% figure;
% for i = 1:4
%     subplot(3,4,i);
%     imagesc([0,1],[0,60], Gap.avgExp(:,:,i));
%     title([Gap.Name{i}, ': Expression Pattern'])
%     xlabel('AP Position (%EL)')
%     ylabel('Time into nc14 (min)')
%     colormap jet;
% end
h = figure('units','normalized','outerposition',[0 0 1 0.5]);
%Plot model
subplot(1,2,1)
imagesc([0,1],[0,60], activeNucleiModel,[0,1])
title('Modeled Eve Expression (% Active Nuclei)')
xlabel('AP Position (%EL)')
ylabel('Time into nc14 (min)')
colorbar

%Plot seed plot
subplot(1,2,2)
imagesc([0,1],[0,60], miniCP.activeNuclei(modelRange,:,2),[0,1])
title('Observed Eve Expression (% Active Nuclei)')
xlabel('AP Position (%EL)')
ylabel('Time into nc14 (min)')
colormap jet; colorbar

% % %Description in the middle
% subplot(3,4,8);
% text(0.2,0.5,Gap.Description)
% h = gca;
% h.XTick = []; h.YTick = []; h.XTickLabel = []; h.YTickLabel = [];

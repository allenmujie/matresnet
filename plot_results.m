function plot_results(expDir, datasetName, measures, savePath)
% Usage example: plot_results('exp', 'cifar', {'error'}, 'exp/summary.pdf');

if ~exist('datasetName', 'var') || isempty(datasetName), 
  datasetName = 'cifar';
end
if ~exist('measures', 'var') || isempty(measures), 
  if strcmpi(datasetName, 'cifar'), measures = {'error'}; 
  elseif strcmpi(datasetName, 'imagenet'), measures = {'error', 'error5'};
  end
end
if ~exist('savePath', 'var'), 
  savePath = expDir;
end

if ischar(measures), measures = {measures}; end
if isempty(strfind(savePath,'.pdf')) || strfind(savePath,'.pdf')~=numel(savePath)-3, 
  savePath = fullfile(savePath,[datasetName '-summary.pdf']);
end

plots = {'plain', 'resnet'}; 
figure(1) ; clf ;
cmap = lines;
for p = plots
  p = char(p) ;
  list = dir(fullfile(expDir,sprintf('%s-%s-*',datasetName,p)));
  tokens = regexp({list.name}, sprintf('%s-%s-([\\d]+)',datasetName,p), 'tokens'); 
  Ns = cellfun(@(x) sscanf(x{1}{1}, '%d'), tokens);
  Ns = sort(Ns); 

  for k = 1:numel(measures), 
    subplot(k,numel(plots),find(strcmp(p,plots)));
    hold on;
    leg = {}; Hs = []; nEpoches = 0;
    for n=Ns,
      tmpDir = fullfile(expDir,sprintf('%s-%s-%d',datasetName,p,n));
      epoch = findLastCheckpoint(tmpDir);
      if epoch==0, continue; end
      load(fullfile(tmpDir,sprintf('net-epoch-%d.mat',epoch)),'stats');
      plot([stats.train.(measures{k})], ':','Color',cmap(find(Ns==n),:),'LineWidth',1.5); 
      Hs(end+1) = plot([stats.val.(measures{k})], '-','Color',cmap(find(Ns==n),:),'LineWidth',1.5); 
      leg{end+1} = sprintf('%s-%d',p,6*n+2);
      if numel(stats.train)>nEpoches, nEpoches = numel(stats.train); end
    end
    xlabel('epoch') ;
    ylabel(sprintf('%s', measures{k}));
    title(p) ;
    legend(Hs,leg{:},'Location','NorthEast') ;
%    axis square; 
%    ylim([0 .25]);
    ylim([0 .75]);
    xlim([1 nEpoches]);
    set(gca,'YGrid','on');
  end
end
drawnow ;
print(1, savePath, '-dpdf') ;
end

function epoch = findLastCheckpoint(modelDir)
list = dir(fullfile(modelDir, 'net-epoch-*.mat')) ;
tokens = regexp({list.name}, 'net-epoch-([\d]+).mat', 'tokens') ;
epoch = cellfun(@(x) sscanf(x{1}{1}, '%d'), tokens) ;
epoch = max([epoch 0]) ;
end

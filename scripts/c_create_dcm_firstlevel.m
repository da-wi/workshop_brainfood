%% change this
paths.root =  'C:\Users\David.Willinger\Documents\workshop_brainfood\';
%%

% dont touch
paths.masterfile =   fullfile(paths.root, 'data\subjects.csv'); 
paths.data = fullfile(paths.root, '\dcm\1_lvl\');

% Define subjects
excludes = {'pmdd-49'};
subjects =           readtable(paths.masterfile); 
subjects = subjects(find(~contains(subjects.id,excludes)),:);


% start script
prompt = sprintf('Path is: %s  Are you sure? Y/N [N]: ',paths.data);
str = input(prompt,'s');
if isempty(str) | strcmp(str,'n') | strcmp(str,'no') | strcmp(str,'No')
    str = 'N';
end
if strcmp(str,'N')
    fprintf('Abort.\n');
    return
end

regions = {  'VOI_precuneus_0_-52_7_1.mat',...
             'VOI_medial_pfc_-1_54_27_1.mat',...
             'VOI_acc_0_21_36_1.mat',...
             'VOI_l_amy_-19_-2_-21_1.mat',...
             'VOI_r_amy_19_-2_-21_1.mat'
             };

batches = {};
for s = 1:height(subjects)
    clear DCM xY;
    
    subDir = fullfile(paths.data,subjects.id{s});
    cd(subDir);
    % Load regions of interest
    %--------------------------------------------------------------------------
    for r = 1:numel(regions)
        % load VOI from _2
        load(fullfile(paths.data,subjects.id{s},regions{r}),'xY');
        DCM.xY(r) = xY;  
    end
    
    DCM.n = length(DCM.xY);      % number of regions
    DCM.v = length(DCM.xY(1).u); % number of time points    
    DCM.Y.dt  = 2.3;             % TR = 2.3s
    DCM.Y.X0  = DCM.xY(1).X0;

    for i = 1:DCM.n
        DCM.Y.y(:,i)  = DCM.xY(i).u;
        DCM.Y.name{i} = DCM.xY(i).name;
    end
    
    Y  = DCM.Y;                           % responses
    v  = DCM.v;                             % number of scans
    n  = DCM.n;    
    
    DCM.Y.Q    = spm_Ce(ones(1,n)*v);
    DCM.U.u    =  zeros(v,1);
    DCM.U.idx  = 0;
    DCM.U.name = {'null'};
    
    DCM.a = ones(DCM.n);
    
    DCM.b  = zeros(n,n,0);
    DCM.c  = zeros(n,1);
    DCM.d = zeros(n,n,0);
    
    DCM.TE     = 0.04;
    DCM.delays = repmat(DCM.Y.dt/2,DCM.n,1); % TR = 2.3
    
    DCM.options.nonlinear  = 0;
    DCM.options.two_state  = 0;
    DCM.options.stochastic = 0;
    DCM.options.nograph    = 1;
    DCM.options.centre     = 1;
    DCM.options.Nmax       = 5;
    DCM.options.maxnodes   = 5;
    DCM.options.order      = 5;
    DCM.options.maxit      = 128;
    DCM.options.analysis   = 'CSD';
    DCM.options.induced    = 1;
    % save(fullfile(paths.data,subjects.id{s},'DCM_AMY'),'DCM'); 
end
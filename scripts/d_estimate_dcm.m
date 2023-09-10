%% change this
paths.root =  'C:\Users\David.Willinger\Documents\workshop_brainfood\';
%%

% dont touch
paths.masterfile =   fullfile(paths.root, 'data\subjects.csv'); 
paths.data = fullfile(paths.root, '\dcm\1_lvl\');
paths.data_2lvl = fullfile(paths.root, '\dcm\2_lvl\');

% Define subjects
% pmdd-49 ... no MRI data recorded 
% pmdd-60 ... no SSRI data
excludes = {'pmdd-49','pmdd-60'};
subjects =           readtable(paths.masterfile); 
subjects = subjects(find(~contains(subjects.id,excludes)),:);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% FIRST LEVEL ANALYSIS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Load the first-level DCM structures into a struct (GCM) with dimension
% models x subjects


dcms = {};
for s = 1:height(subjects)
        dcms{s,1} = char(fullfile(paths.data,subjects.id{s},'DCM_AMY.mat'));   
end
GCM = cellstr(dcms);

% Comment this if already estimated, uncomment to estimate 1st level (takes
% some hours)
% [GCM,M,PEB,HCM] = spm_dcm_peb_fit(GCM(:,1));

%save(fullfile(paths.data_2lvl,'HCM_AMY.mat'), 'HCM' );
load(fullfile(paths.data_2lvl,'HCM_AMY.mat') );

% diagnostics, subjects with model variance explained < 10%?
HCM(:,end) = spm_dcm_fmri_check(HCM(:,end));
ve = []; % variance explained & max. parameter
for i = 1:numel(HCM(:,end))
    ve = [ve; HCM{i,end}.diagnostics(1) HCM{i,end}.diagnostics(2)]
end    


% check variance explained
mean(ve(strcmp(subjects.group,'hc')))
std(ve(strcmp(subjects.group,'hc')))
mean(ve(strcmp(subjects.group,'pmdd')))
std(ve(strcmp(subjects.group,'pmdd')))



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SECOND LEVEL ANALYSIS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% priors
M.alpha = 1;      % optional scaling to specify M.bC [default = 1]
M.beta  = 16;     % optional scaling to specify M.pC [default = 16]
M.hE    = 0;      % 2nd-level prior expectation of log precisions [default: 0]
M.hC    = 1/16;   % 2nd-level prior covariances of log precisions [default: 1/16]
M.Q     = 'single';  % covariance components: {'single','fields','all','none'}
M.X     = ones(numel(HCM), 1);
M.Xnames = {'Overall mean'};

% 1. option: use Bayesian model comparison to reduce the full model on a
% per-connection basis
DCM_full = HCM{1};

% IMPORTANT: If the model has already been estimated, clear out the old priors, or changes to DCM.a,b,c will be ignored
if isfield(DCM_full,'M')
    DCM_full = rmfield(DCM_full ,'M');
end

% full model (1)
DCM = {};
DCM{1} = DCM_full;

% top-down model (2)
DCM{2} = DCM_full;
DCM{2}.a(1,4) = 0;
DCM{2}.a(1,5) = 0;
DCM{2}.a(2,4) = 0;
DCM{2}.a(2,5) = 0;

% bottom-up model (3)
DCM{3} = DCM_full;
DCM{3}.a(4,1) = 0;
DCM{3}.a(5,1) = 0;
DCM{3}.a(4,2) = 0;
DCM{3}.a(5,2) = 0;

PEB_A =  spm_dcm_peb(HCM_ssri(:,end), M, {'A'});   % Hierarchical (PEB) inversion of DCMs using BMR and VL
[BMA,BMR] = spm_dcm_peb_bmc(PEB_A, DCM(1:3)); % Hierarchical (PEB) model comparison and averaging (2nd level)
spm_dcm_peb_review(BMA,HCM_ssri(:,1));             % Review tool for DCM PEB models


% 2. option: use Bayesian model comparison to reduce the full model on a
% per-connection basis
% Rather than copmaring specific hypotheses, we can prune away
% parameters not contributing to the model evidence (POST-HOC search)ed
% 
PEB_ssri_A = spm_dcm_peb(HCM_ssri(:,1), M, {'A'});
BMA_ssri_A = spm_dcm_peb_bmc(PEB_ssri_A); %

spm_dcm_peb_review(PEB_ssri_A,HCM_ssri(:,1));
spm_dcm_peb_review(BMA_ssri_A,HCM_ssri(:,1));


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Analysis with covariates
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% create the peb models 
% covariate with controls
% remove excluded from HCM struct
% ATTENTION: make sure `subjects` is in the right order!! (1. PMDD, 2. HC)

% remove subject no data was recorded from to match DCM_AMY
excludes = {'pmdd-49'};
subjects =           readtable(paths.masterfile); 
subjects = subjects(find(~contains(subjects.id,excludes)),:);

% remove subject with no SSRI data for second level analysis
subjects(strcmp(subjects.id,'pmdd-60'),:).excluded = 1;
HCM_ssri = HCM(~subjects.excluded,end); % remove subject in HCM without medication
subjects = subjects(subjects.excluded == 0,:);

subjects.ssrivar = subjects.ssrivar.*2-1;
subjects.ssrivar(strcmp(subjects.group,'hc')) = 0;
X_pmdd_ssri = [ones(length(HCM_ssri),1),strcmp(subjects.group, 'pmdd')*2-1, ...
    subjects.ssrivar subjects.age subjects.sex*2-1 subjects.handedness*2-1  ];

X_pmdd_ssri(:,2:end) = X_pmdd_ssri(:,2:end) - mean(X_pmdd_ssri(:,2:end));

M.X = X_pmdd_ssri;
M.Xnames = {'Overall mean','Group diff. (pmdd>hc)','ssri','age','sex','handedness'};
%
PEB_ssri_A = spm_dcm_peb(HCM_ssri(:,1), M, {'A'});
BMA_ssri_A = spm_dcm_peb_bmc(PEB_ssri_A); %

% spm_dcm_peb_review(PEB_ssri_A,HCM_ssri(:,1));
spm_dcm_peb_review(BMA_ssri_A,HCM_ssri(:,1));

% save(fullfile(paths.data_2lvl,'PEB_ssri_A.mat'), 'PEB_ssri_A' );
% save(fullfile(paths.data_2lvl,'BMA_ssri_A.mat'), 'BMA_ssri_A' );


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%5
% LEAVE ONE OUT CROSS VALIDATION FOR GROUP
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%5
observed_group = X_pmdd_ssri(:,2) > 0;
sign_params = {'A(1,4)','A(1,5)','A(2,4)','A(2,5)','A(2,2)','A(4,2)','A(5,2)','A(3,3)'};
[qE,qC,Q] = spm_dcm_loo(HCM_ssri(:,end),X_pmdd_ssri,sign_params);
[pc.X,pc.Y,pc.T,pc.AUC] = perfcurve(observed_group,Q(2,:),1,'NBoot',1000, 'BootType','cper')

qE_group = {};
qC_group = {};
Q_group = {};
for s = 1:numel(sign_params)
    [qE_tmp,qC_tmp,Q_tmp] = spm_dcm_loo(HCM_ssri(:,end),X_pmdd_ssri,sign_params{s});
    qE_group{s} = qE_tmp;
    qC_group{s} = qC_tmp;
    Q_group{s} = Q_tmp; 
end

pc_X_group = {};
pc_Y_group = {};
pc_T_group = {};
pc_AUC_group = {};
for s = 1:numel(sign_params)
    [pc_X_group{s},pc_Y_group{s},pc_T_group{s},pc_AUC_group{s}] = perfcurve(observed_group,Q_group{s}(2,:),1,'NBoot',1000, 'BootType','cper');
end

cellfun(@display,pc_AUC_group)

save(fullfile(paths.data_2lvl,'loocv_group.mat'), 'pc_X_group','pc_Y_group','pc_T_group','pc_AUC_group' );


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%5
% LEAVE ONE OUT CROSS VALIDATION FOR SSRI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%5
sign_params = {'A(1,1)','A(2,2)','A(3,3)'};
X_pmdd_ssri_loo = X_pmdd_ssri;
tmp = X_pmdd_ssri_loo(:,2);
X_pmdd_ssri_loo(:,2) = X_pmdd_ssri_loo(:,3);
X_pmdd_ssri_loo(:,3) = tmp;

[qE,qC,Q] = spm_dcm_loo(HCM_ssri(:,end),X_pmdd_ssri_loo,sign_params{3});
% A(1,1), r = 0.26; p = 0.02152 sig
% A(2,2), r= .29; p = .01237 sig.
% A(3,3), r = .12; p = .17414 n.s.


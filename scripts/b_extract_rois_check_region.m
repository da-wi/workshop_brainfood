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


rois_coord = {
[-19 -2 -21] 
[19 -2 -21]
[0 -52 7]
[-1 54 27]
[0 21 36]
};

rois_names = {
    'l_amy',
    'r_amy',
    'precuneus',
    'medial_pfc',
    'acc'
};

rois_name = {'VOI_l_amy_-19_-2_-21_1.mat',...
             'VOI_r_amy_19_-2_-21_1.mat',...
             'VOI_precuneus_0_-52_7_1.mat',...
             'VOI_medial_pfc_-1_54_27_1.mat',...
             'VOI_acc_0_21_36_1.mat'
             };

coords = []; % for brainnetviewer
rois = [];
for s = 1:height(subjects)
    for r = 1:numel(rois_name)
        try
            VOI = load(fullfile(paths.data, subjects.id{s},  rois_name{r} ));
            coords = [coords; VOI.xY.xyz' r 1];
            rois{s,r} = VOI.xY.s(1)/sum(VOI.xY.s);
        catch e
            coords = [coords; nan(1,5)];
            rois{s,r} = NaN;
        end    
    end 
end

% preprocess rois
rois=cell2table(rois);
rois.id = subjects.id(:);
excludes = rois.id(isnan(rois.rois1) | isnan(rois.rois2) | isnan(rois.rois3) | isnan(rois.rois4)  | isnan(rois.rois5)  )';

%rois= {};
% preprocess coords and generate node file
writematrix(coords,fullfile(paths.data,'DCM.ROIs.csv'), 'Delimiter','\t')


return

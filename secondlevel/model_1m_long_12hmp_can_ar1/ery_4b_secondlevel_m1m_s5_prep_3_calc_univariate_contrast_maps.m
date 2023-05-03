%% ery_4a_secondlevel_m6m_s5_prep_3_calc_univariate_contrast_maps.m
%
%
% USAGE
%
% This prep script 
% 1) calculates contrast images from first-level beta/con condition images included in prep_2 script, and stores them as CANlab's fmri_data_st objects 
% 2) performs l2norm-rescaling of resulting contrast images
% 3) performs quality control, including plots if requested in a2 script
% 4) saves the relevant resulting objects/variables in a .mat file to resultsdir
% 5) publishes an html report (run using Matlab's publish function)
%
%
% NOTE: We can include image sets with different
% numbers of images, as occurs with between-person designs, as
% long as the contrast weights are zero for all elements with
% different numbers of images.
%
%
% OPTIONS
%
% dofullplot: default true, can set to false to save time, but not recommended for quality control purposes
% omit_histograms: default false, can set to false to save time, especially in case of large samples but not recommended for quality control purposes
% dozipimages: default false, to avoid load on data upload/download when re-running often, true is useful to save space when running final analyses
%
%__________________________________________________________________________
%
% modified by: Lukas Van Oudenhove
% date:   Dartmouth, May, 2022
%
%__________________________________________________________________________
% @(#)% prep_3_calc_univariate_contrast_maps_and_save.m         v1.2
% last modified: 2022/09/02


%% RAW AND L2NORM-RESCALED CONTRAST IMAGES FROM RAW CONDITION IMAGES
% -------------------------------------------------------------------------

fprintf('\n\n');
printhdr('CALCULATING CONTRAST IMAGES FROM RAW CONDITION IMAGES AND CONVERTING TO FMRI_DATA_ST OBJECTS');
fprintf('\n\n');

if ~isfield(DAT, 'contrasts') || isempty(DAT.contrasts)
    % skip
    return
end

k = size(DAT.conditions,2);

% GET SIZES OF DATA_OBJ
% -------------------------------------------------------------------------

clear sz

for i = 1:k
    sz(i, :) = size(DATA_OBJ{i}.dat); 
end

sz = sz(:, 2);

for i = 1:k
    DATA_OBJ{i} = replace_empty(DATA_OBJ{i},'voxels');
end


% CREATE DATA_OBJ_CON, RESCALE, AND QC
% -------------------------------------------------------------------------

for c = 1:size(DAT.contrasts, 1)
    
    % PREP
    % ---------------------------------------------------------------------
    
    % initialize : shell object, keep same space/volume info
    wh = find(DAT.contrasts(c, :));
    
    my_size = sz(wh(1));  
    
    % check sizes and make sure they are the same
    if ~all(sz(wh) == sz(wh(1)))
        fprintf('\nNot all image set sizes are the same for contrast %d\n\n', c);
    end
    
    % CREATE CONTRAST OBJECTS & RESCALE BY L2NORM
    % ---------------------------------------------------------------------
    
    fprintf('\n');
    fprintf('%s\nCreating fmri_data_st object for raw contrast: %s\n%s\n', dashes, DAT.contrastnames{c}, dashes);
    fprintf('\n');
    
    DATA_OBJ_CON{c} = DATA_OBJ{wh(1)};
    [DATA_OBJ_CON{c}.image_names, DATA_OBJ_CON{c}.fullpath] = deal([]);
        
    DATA_OBJ_CON{c}.dat = zeros(size(DATA_OBJ{wh(1)}.dat));
    
    for i = 1:k
        
        % add data * contrast weight
        condat = DATA_OBJ{i}.dat .* DAT.contrasts(c, i);
        
        if DAT.contrasts(c, i) == 0
            % Skip.  This allows us to include image sets with different
            % numbers of images, as occurs with between-person designs, as
            % long as the contrast weights are zero for all elements with
            % different numbers of images.
            continue
        end
        
        if size(condat, 2) ~= my_size
            fprintf('\nCondition %d : number of images does not match. Check DATA_OBJ images and contrasts\n', i);
            error('exiting...')
        end
        
        DATA_OBJ_CON{c}.dat = DATA_OBJ_CON{c}.dat + condat;
        
    end
    
%     DATA_OBJ_CON{c} = remove_empty(DATA_OBJ_CON{c}); % lukasvo76: redundant since fmri_data.enforce_variable_types below includes remove_empty
    DATA_OBJ_CON{c}.image_names = DAT.contrastnames;
    DATA_OBJ_CON{c}.source_notes = DAT.contrastnames;
    
    % rescale contrast objects by l2norm % added by @lukasvo76 01/03/21
    fprintf('\n');
    fprintf('%s\nRescaling fmri_data_st object by l2norm for raw contrast: %s\n%s\n', dashes, DAT.contrastnames{c}, dashes);
    fprintf('\n');
    
    DATA_OBJ_CONscc{c} = rescale(DATA_OBJ_CON{c}, 'l2norm_images');
    
    % enforce variable types in objects to save space
    DATA_OBJ_CON{c} = enforce_variable_types(DATA_OBJ_CON{c}); 
    DATA_OBJ_CONscc{c} = enforce_variable_types(DATA_OBJ_CONscc{c}); 
    
    
    % QUALITY CONTROL METRICS & PLOT (OPTIONAL)
    % ------------------------------------------------------------------------
    
    % RAW CONTRAST OBJECTS
    fprintf('\n');
    fprintf('%s\nQC metrics for raw contrast: %s\n%s\n', dashes, DAT.contrastnames{c}, dashes);
    fprintf('\n');
    
    % qc
    [group_metrics, individual_metrics, gwcsf, gwcsfmean] = qc_metrics_second_level(DATA_OBJ_CON{c});
    drawnow; snapnow
    
    % plot
    if dofullplot
        fprintf('\n');
        fprintf('%s\nPlot of raw contrast: %s\n%s\n', dashes, DAT.contrastnames{c}, dashes);
        fprintf('\n');
        
        disp(DATA_OBJ_CON{c}.fullpath)
        
        plot(DATA_OBJ_CON{c},'norunmontages'); % @lukasvo76 turned run montages off, since second level con images are most often not per run
        
        drawnow; snapnow
        
        if ~omit_histograms
              
          % @lukasvo76 commented out since this is redundant (already
          % included as subplot in output of plot() function above
%             hist_han = histogram(DATA_OBJ_CON{c}, 'byimage', 'singleaxis');
%             title([DAT.contrastnames{c} ' histograms for each raw contrast image']);
%             drawnow; snapnow
            
            create_figure('histogram');
            set(gcf,'WindowState','maximized');
            hist_han = histogram(DATA_OBJ_CON{c}, 'byimage', 'by_tissue_type');
            drawnow; snapnow
            
        end
        
    end
    
    % RESCALED CONTRAST OBJECTS
    fprintf('\n');
    fprintf('%s\nQC metrics for l2norm-rescaled contrast: %s\n%s\n', dashes, DAT.contrastnames{c}, dashes);
    fprintf('\n');
    
    % qc
    [group_metrics, individual_metrics, gwcsf, gwcsfmean] = qc_metrics_second_level(DATA_OBJ_CONscc{c});
    drawnow; snapnow
    
    % plot
    if dofullplot
        fprintf('\n');
        fprintf('%s\nPlot of l2norm-rescaled contrast: %s\n%s\n', dashes, DAT.contrastnames{c}, dashes);
        fprintf('\n');
        
        disp(DATA_OBJ_CONscc{c}.fullpath)
        
        plot(DATA_OBJ_CONscc{c},'norunmontages'); % @lukasvo76 turned run montages off, since second level con images are most often not per run
        
        drawnow; snapnow
        
        if ~omit_histograms
            
          % @lukasvo76 commented out since this is redundant (already
          % included as subplot in output of plot() function above
%             hist_han = histogram(DATA_OBJ_CONscc{c}, 'byimage', 'singleaxis');
%             title([DAT.contrastnames{c} ' histograms for each l2norm-rescaled contrast image']);
%             drawnow; snapnow
            
            create_figure('histogram_l2norm');
            set(gcf,'WindowState','maximized');
            hist_han_l2norm = histogram(DATA_OBJ_CONscc{c}, 'byimage', 'by_tissue_type');
            drawnow; snapnow
            
        end
        
    end
    
end


%% CONTRAST IMAGES FROM Z-SCORED CONDITION IMAGES
% -------------------------------------------------------------------------

fprintf('\n\n');
printhdr('CALCULATING CONTRAST IMAGES FROM Z-SCORED CONDITION IMAGES AND CONVERTING TO FMRI_DATA_ST OBJECTS');
fprintf('\n\n');

for i = 1:k
    DATA_OBJsc{i} = replace_empty(DATA_OBJsc{i});
end

% CREATE DATA_OBJ_CONsc, AND QC
% -------------------------------------------------------------------------

for c = 1:size(DAT.contrasts, 1)

    % PREP
    % ---------------------------------------------------------------------
    
    fprintf('\n');
    fprintf('%s\nCreating fmri_data_st object for z-scored contrast: %s\n%s\n', dashes, DAT.contrastnames{c}, dashes);
    fprintf('\n');
    
    % initialize : shell object, keep same space/volume info
    wh = find(DAT.contrasts(c, :));
    
    my_size = sz(wh(1));  
    
    % check sizes and make sure they are the same
    if ~all(sz(wh) == sz(wh(1)))
        fprintf('\nNot all image set sizes are the same for contrast %d\n\n', c);
    end
    
    % CREATE CONTRAST OBJECTS
    DATA_OBJ_CONsc{c} = DATA_OBJsc{wh(1)};
    [DATA_OBJ_CONsc{c}.image_names, DATA_OBJ_CONsc{c}.fullpath] = deal([]);
    DATA_OBJ_CONsc{c}.dat = zeros(size(DATA_OBJsc{wh(1)}.dat));
    
    
    for i = 1:k
        
        % add data * contrast weight
        condat = DATA_OBJsc{i}.dat .* DAT.contrasts(c, i);
        
        if DAT.contrasts(c, i) == 0
            % Skip.  This allows us to include image sets with different
            % numbers of images, as occurs with between-person designs, as
            % long as the contrast weights are zero for all elements with
            % different numbers of images.
            continue
        end
        
        if size(condat, 2) ~= my_size
            fprintf('Condition %3.0f : number of images does not match. Check DATA_OBJsc images and contrasts.', i);
            error('exiting.')
        end
        
        DATA_OBJ_CONsc{c}.dat = DATA_OBJ_CONsc{c}.dat + condat;
        
    end
    
%     DATA_OBJ_CONsc{c} = remove_empty(DATA_OBJ_CONsc{c}); % lukasvo76: redundant since fmri_data.enforce_variable_types below includes remove_empty
    DATA_OBJ_CONsc{c}.image_names = DAT.contrastnames;
    DATA_OBJ_CONsc{c}.source_notes = DAT.contrastnames;
    
    % enforce variable types in objects to save space
    DATA_OBJ_CONsc{c} = enforce_variable_types(DATA_OBJ_CONsc{c}); 

    
    % QUALITY CONTROL METRICS & PLOT (OPTIONAL)
    % ------------------------------------------------------------------------
    
    fprintf('\n');
    fprintf('%s\nQC metrics for contrast (from z-scored condition images): %s\n%s\n', dashes, DAT.contrastnames{c}, dashes);
    fprintf('\n');
    
    % qc
    [group_metrics, individual_metrics, gwcsf, gwcsfmean] = qc_metrics_second_level(DATA_OBJ_CONsc{c});
    drawnow; snapnow
    
    % plot
    if dofullplot
        fprintf('\n');
        fprintf('%s\nPlot of contrast (from z-scored condition images): %s\n%s\n', dashes, DAT.contrastnames{c}, dashes);
        disp(DATA_OBJ_CONsc{c}.fullpath)
        
        plot(DATA_OBJ_CONsc{c},'norunmontages'); % @lukasvo76 turned run montages off, since second level con images are most often not per run
        
        drawnow; snapnow
        
        if ~omit_histograms

          % @lukasvo76 commented out since this is redundant (already
          % included as subplot in output of plot() function above  
%             hist_han = histogram(DATA_OBJ_CONsc{c}, 'byimage', 'singleaxis');
%             title([DAT.contrastnames{c} ' histograms for each contrast image (from z-scored condition images)']);
%             drawnow; snapnow
            
            create_figure('histogram_zscore');
            set(gcf,'WindowState','maximized');
            hist_han_zscore = histogram(DATA_OBJ_CONsc{c}, 'byimage', 'by_tissue_type');
            drawnow; snapnow
            
        end
        
    end
    
end


%% SAVE RESULTS
% ------------------------------------------------------------------------

fprintf('\n\n');
printhdr('SAVE CONTRAST DATA OBJECTS IN contrast_data_objects.mat');
fprintf('\n\n');

savefilenamedata = fullfile(resultsdir, 'contrast_data_objects.mat');   % both unscaled and two versions of scaled
save(savefilenamedata, 'DATA_OBJ_CON*', '-v7.3');                       % Note: 6/7/17 Tor switched to -v7.3 format by default 


%% GET CONTRASTS IN GLOBAL GRAY, WHITE, CSF VALUES
% -------------------------------------------------------------------------

fprintf('\n\n');
printhdr('CALCULATE CONTRASTS IN GRAY/WHITE/CSF VALUES');
fprintf('\n\n');

DAT.gray_white_csf_contrasts = {};

for c = 1:size(DAT.contrasts, 1)
    
    wh = find(DAT.contrasts(c, :));
    
    DAT.gray_white_csf_contrasts{c} = zeros(size(DAT.gray_white_csf{wh(1)}));
    
    for i = 1:k
        
        if DAT.contrasts(c, i) == 0
            % Skip.  This allows us to include image sets with different
            % numbers of images, as occurs with between-person designs, as
            % long as the contrast weights are zero for all elements with
            % different numbers of images.
            continue
        end
        
        % add data * contrast weight
        DAT.gray_white_csf_contrasts{c} = DAT.gray_white_csf_contrasts{c} + DAT.gray_white_csf{i} .* DAT.contrasts(c, i);
        
    end
    
end


%% ADD TO PREVIOUSLY SAVED RESULTS
% -------------------------------------------------------------------------

fprintf('\n\n');
printhdr('ADDED CONTRAST GRAY/WHITE/CSF TO DAT in image_names_and_setup.mat');
fprintf('\n\n');

savefilename = fullfile(resultsdir, 'image_names_and_setup.mat');
save(savefilename, '-append', 'DAT');

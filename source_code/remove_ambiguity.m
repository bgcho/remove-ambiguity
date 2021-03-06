heading = heading(1:stride:end);
ping_id = ping_id(1:stride:end,:);
src_lat = src_lat(1:stride:end);
src_lon = src_lon(1:stride:end);
src_utm_x = src_utm_x(1:stride:end);
src_utm_y = src_utm_y(1:stride:end);
timestamp = timestamp(1:stride:end);
im_all = im_all(:,:,1:stride:end);


% Get the contour, mask, and center of the detected objects and real-ghost pair indices
[contour_obj, mask_obj, cntr_obj, real_ghost_pair] = get_obj(grid_x, grid_y, im_all, src_utm_x, src_utm_y, heading, th, near_src_range);

% Get the SIFT flow map
addpath(fullfile(pwd,'SIFTflow'));
addpath(fullfile(pwd,'SIFTflow','mexDenseSIFT'));
addpath(fullfile(pwd,'SIFTflow','mexDiscreteFlow'));

SIFTflowpara.alpha=2*255;
SIFTflowpara.d=160*255;
SIFTflowpara.gamma=0*0.005*255;
SIFTflowpara.nlevels=4;
SIFTflowpara.wsize=2;
SIFTflowpara.topwsize=10;
SIFTflowpara.nTopIterations = 60;
SIFTflowpara.nIterations= 30;

no_image = size(im_all,3);
file_prelude = [num2str(no_image) '_'];

for ii = 1:no_image-1
	im1 = im_all(:,:,ii);
	im2 = im_all(:,:,ii+1);
	tmp_SIFTflow = get_SIFT_flow(im1, im2, SIFTflowpara);
	SIFTflowx_map1(:,:,ii) = tmp_SIFTflow(:,:,1);
	SIFTflowy_map1(:,:,ii) = tmp_SIFTflow(:,:,2);
end
SIFTflowx_map2(:,:,1) = SIFTflowx_map1(:,:,1);
SIFTflowx_map2 = cat(3,SIFTflowx_map2, SIFTflowx_map1);
SIFTflowx_map1(:,:,end+1) = SIFTflowx_map1(:,:,end);
% SIFTflowx_map = (SIFTflowx_map1+SIFTflowx_map2)/2;
SIFTflowx_map = max(SIFTflowx_map1,SIFTflowx_map2);

SIFTflowy_map2(:,:,1) = SIFTflowy_map1(:,:,1);
SIFTflowy_map2 = cat(3,SIFTflowy_map2, SIFTflowy_map1);
SIFTflowy_map1(:,:,end+1) = SIFTflowy_map1(:,:,end);
% SIFTflowy_map = (SIFTflowy_map1+SIFTflowy_map2)/2;
SIFTflowy_map = max(SIFTflowy_map1,SIFTflowy_map2);

for ii = 1:no_image
	SIFTflow{ii}(:,:,1) = SIFTflowx_map(:,:,ii);
	SIFTflow{ii}(:,:,2) = SIFTflowy_map(:,:,ii);
	tmp_flow_mag = sqrt(SIFTflowx_map(:,:,ii).^2+SIFTflowy_map(:,:,ii).^2);
	SIFTflow_mag(:,:,ii) = (tmp_flow_mag - min(tmp_flow_mag(:)))*50/(max(tmp_flow_mag(:))-min(tmp_flow_mag(:)));
end

% Get the LK optical flow map
addpath(fullfile(pwd,'LK'));
% set parameters
nlevels = 3;
winsize = 3;
medfiltsize = 11;
nIterations = 5;

% use coarse to fine lucas kanade to obtain optical flow field
for ii = 1:no_image-1
	im1 = im_all(:,:,ii);
	im2 = im_all(:,:,ii+1);
	tic; [u,v,warpI2] = coarse2fine_lk(im1,im2,nlevels,winsize,medfiltsize,nIterations); toc
	LKflowx_map1(:,:,ii) = u;
	LKflowy_map1(:,:,ii) = v;
end
LKflowx_map2(:,:,1) = LKflowx_map1(:,:,1);
LKflowx_map2 = cat(3,LKflowx_map2, LKflowx_map1);
LKflowx_map1(:,:,end+1) = LKflowx_map1(:,:,end);
% LKflowx_map = (LKflowx_map1+LKflowx_map2)/2;
LKflowx_map = max(LKflowx_map1,LKflowx_map2);

LKflowy_map2(:,:,1) = LKflowy_map1(:,:,1);
LKflowy_map2 = cat(3,LKflowy_map2, LKflowy_map1);
LKflowy_map1(:,:,end+1) = LKflowy_map1(:,:,end);
% LKflowy_map = (LKflowy_map1+LKflowy_map2)/2;
LKflowy_map = max(LKflowy_map1,LKflowy_map2);

for ii = 1:no_image
	LKflow{ii}(:,:,1) = LKflowx_map(:,:,ii);
	LKflow{ii}(:,:,2) = LKflowy_map(:,:,ii);
	tmp_flow_mag = sqrt(LKflowx_map(:,:,ii).^2+LKflowy_map(:,:,ii).^2);
	LKflow_mag(:,:,ii) = (tmp_flow_mag - min(tmp_flow_mag(:)))*50/(max(tmp_flow_mag(:))-min(tmp_flow_mag(:)));
end

% Get the HS optical flow map
addpath(fullfile(pwd,'HS'));
for ii = 1:no_image-1
	im1 = im_all(:,:,ii);
	im2 = im_all(:,:,ii+1);
	tic; [u,v] = HS(im1,im2); toc
	HSflowx_map1(:,:,ii) = u;
	HSflowy_map1(:,:,ii) = v;
end
HSflowx_map2(:,:,1) = HSflowx_map1(:,:,1);
HSflowx_map2 = cat(3,HSflowx_map2, HSflowx_map1);
HSflowx_map1(:,:,end+1) = HSflowx_map1(:,:,end);
% HSflowx_map = (HSflowx_map1+HSflowx_map2)/2;
HSflowx_map = max(HSflowx_map1,HSflowx_map2);

HSflowy_map2(:,:,1) = HSflowy_map1(:,:,1);
HSflowy_map2 = cat(3,HSflowy_map2, HSflowy_map1);
HSflowy_map1(:,:,end+1) = HSflowy_map1(:,:,end);
% HSflowy_map = (HSflowy_map1+HSflowy_map2)/2;
HSflowy_map = max(HSflowy_map1,HSflowy_map2);

for ii = 1:no_image
	HSflow{ii}(:,:,1) = HSflowx_map(:,:,ii);
	HSflow{ii}(:,:,2) = HSflowy_map(:,:,ii);
	tmp_flow_mag = sqrt(HSflowx_map(:,:,ii).^2+HSflowy_map(:,:,ii).^2);
	HSflow_mag(:,:,ii) = (tmp_flow_mag - min(tmp_flow_mag(:)))*50/(max(tmp_flow_mag(:))-min(tmp_flow_mag(:)));
end



N_h = 2;
h_bf = figure; set(gcf, 'position', [3 30 1250 633])
h_bf_amb_corr = tight_subplot(N_h,ceil(no_image/N_h), [.1 .1], [.1 .1], [.1 .1]); set(h_bf_amb_corr([1:length(h_bf_amb_corr)]>no_image), 'visible','off')
for ii = 1:no_image
	% subplot(2,ceil(no_image/2),ii)
	axes(h_bf_amb_corr(ii))
	imagesc((grid_x-center_x)/1000, (grid_y-center_y)/1000, im_all(:,:,ii)); hold on
	[c_bathy, h_bathy] = contour((bathygrid_x-center_x)/1000, (bathygrid_y-center_y)/1000, bathy_map, [-300:50:0],'k--');
	axis xy equal tight
	caxis([80 170])
	set(gca,'fontsize',12, 'fontweight','normal')
	title(h_bf_amb_corr(ii), datestr(timestamp(ii)))
	xlim([min((grid_x-center_x)/1000) max((grid_x-center_x)/1000)])
	ylim([min((grid_y-center_y)/1000) max((grid_y-center_y)/1000)])
	if ii==1
		xlabel('Easting (km)'); ylabel('Northing (km)');
		cbh = colorbar; set(cbh,'fontsize',12,'fontweight','normal'); ylabel(cbh, 'Intensity');		
	end
	colormap(cmap)
end
axes_first = get(h_bf_amb_corr(1),'position');
axes_other = get(gca,'position');
set(h_bf_amb_corr(1), 'position', [axes_first(1:2) axes_other(3:4)])
axes_cbh = get(cbh,'position');
set(cbh, 'position', [axes_cbh(1)+0.05 axes_first(2) axes_cbh(3) axes_first(4)])
suptitle('Before ambiguity correction')
set(gcf,'paperpositionmode','auto')

%keyboard

saveas(h_bf,['../result_data/' file_prelude 'bf_amb_corr'],'fig')
saveas(h_bf,['../result_data/' file_prelude 'bf_amb_corr_'],'png')
saveas(h_bf,['../result_data/' file_prelude 'bf_amb_corr_'],'epsc')


% Determine the real & ambiguous object
%flow_type = input('Choose the flow type to remove ambiguity: (LK/HS/SIFT)','s');
%switch lower(flow_type)
%case 'lk'
%	flow_mag = LKflow_mag;
%case 'hs'
%	flow_mag = HSflow_mag;
%case 'sift'
%	flow_mag = SIFTflow_mag;
%end

flow_type = {'LK' 'HS' 'SIFT'};


for yy = 1:length(flow_type)
	type = flow_type{yy};

	switch lower(type)
	case 'lk'
		flow_mag = LKflow_mag;
	case 'hs'
		flow_mag = HSflow_mag;
	case 'sift'
		flow_mag = SIFTflow_mag;
	end

	clear real_obj ghost_obj

	for ii = 1:no_image
		real_obj{ii} = [];
		ghost_obj{ii} = [];
		no_object = size(real_ghost_pair{ii},2);
		for jj = 1:no_object
			flow_obj1 = flow_mag(:,:,ii).*mask_obj{ii}(:,:,real_ghost_pair{ii}(1,jj));
			avg_flow_obj1 = sum(sum(flow_obj1))/numel(find(flow_obj1>0));
			std_flow_obj1 = sqrt(sum(sum(flow_obj1.^2))/numel(find(flow_obj1>0)) - avg_flow_obj1^2);
			flow_obj2 = flow_mag(:,:,ii).*mask_obj{ii}(:,:,real_ghost_pair{ii}(2,jj));
			avg_flow_obj2 = sum(sum(flow_obj2))/numel(find(flow_obj2>0));
			std_flow_obj2 = sqrt(sum(sum(flow_obj2.^2))/numel(find(flow_obj2>0)) - avg_flow_obj2^2);
			if avg_flow_obj2-avg_flow_obj1>max(std_flow_obj1, std_flow_obj2)
				real_obj{ii} = [real_obj{ii} real_ghost_pair{ii}(1,jj)];
				ghost_obj{ii} = [ghost_obj{ii} real_ghost_pair{ii}(2,jj)];
			elseif abs(avg_flow_obj1-avg_flow_obj2)<=max(std_flow_obj1, std_flow_obj2)
				real_obj{ii} = [real_obj{ii} real_ghost_pair{ii}(1,jj)];
			else
				real_obj{ii} = [real_obj{ii} real_ghost_pair{ii}(2,jj)];
				ghost_obj{ii} = [ghost_obj{ii} real_ghost_pair{ii}(1,jj)];
			end
		end
		real_obj{ii} = unique(real_obj{ii});
		ghost_obj{ii} = unique(ghost_obj{ii});
	end

	% Remove the data in the ambiguous object 
	mask_ambig = false(length(grid_y), length(grid_x), no_image);
	for ii = 1:no_image
		for jj = 1:length(ghost_obj{ii})
			mask_ambig(:,:,ii) = mask_ambig(:,:,ii) | mask_obj{ii}(:,:,ghost_obj{ii}(jj));		
		end	
		% neighbor = imfilter(double(mask_ambig(:,:,ii)), fspecial('gaussian',32,8), 'same','replicate')>0.01 & ~mask_ambig(:,:,ii);
		mask_ambig(:,:,ii) = imfilter(double(mask_ambig(:,:,ii)), fspecial('disk',30), 'same','replicate')>2e-04;
		neighbor = imfilter(double(mask_ambig(:,:,ii)), fspecial('disk',30), 'same','replicate')>4e-04 & ~mask_ambig(:,:,ii);
		mask_neighbor(:,:,ii) = neighbor;
		cur_image = im_all(:,:,ii);
		% Get the level of the neighbor region of the ambiguity
		level_neighbor{ii} = cur_image(find(neighbor>0));
		[N(:,ii), X(:,ii)] = hist(level_neighbor{ii}, 100);
	end

	im_ambig_rm = im_all.*(~mask_ambig);

	% Fill in the ambiguity region with data from the neighbor region
	% Get the pdf of the neighbor
	glob_level = linspace(min(min(X)), max(max(X)),100).';
	d_level = glob_level(2)-glob_level(1);

	for ii = 1:no_image
		glob_count(:,ii) = interp1(X(:,ii), N(:,ii), glob_level,'nearest','extrap');
		norm_factor = sum(glob_count(:,ii))*d_level;
		glob_pdf(:,ii) = glob_count(:,ii)/norm_factor;
	end

	% Fill pseudo data in the ambiguity region
	for ii = 1:no_image
		lin_indx = find(mask_ambig(:,:,ii)>0);
		if ~isempty(lin_indx)
		rand_num = gen_rand_pdf(glob_level, glob_pdf(:,ii), numel(lin_indx));
		cur_image = im_all(:,:,ii);
		cur_image(lin_indx) = rand_num;
		end
		im_pseudo(:,:,ii) = cur_image;
	end


	h_ghost = figure; set(gcf, 'position', [3 30 1250 633])
	h_am = tight_subplot(N_h,ceil(no_image/N_h), [.1 .1], [.1 .1], [.1 .1]); set(h_am([1:length(h_am)]>no_image), 'visible','off')
	for ii = 1:no_image
		% subplot(2,ceil(no_image/2),ii)
		axes(h_am(ii))
		imagesc((grid_x-center_x)/1000, (grid_y-center_y)/1000, im_ambig_rm(:,:,ii)); hold on
		[c_bathy, h_bathy] = contour((bathygrid_x-center_x)/1000, (bathygrid_y-center_y)/1000, bathy_map, [-300:50:0],'k--');
		axis xy equal tight
		caxis([80 170])
		set(gca,'fontsize',12, 'fontweight','normal')
		title(datestr(timestamp(ii)))
		xlim([min((grid_x-center_x)/1000) max((grid_x-center_x)/1000)])
		ylim([min((grid_y-center_y)/1000) max((grid_y-center_y)/1000)])
		if ii==1, xlabel('Easting (km)'); ylabel('Northing (km)'); cbh = colorbar; set(cbh,'fontsize',12,'fontweight','normal'); ylabel(cbh, 'Intensity'); end
		colormap(cmap)
	end
	axes_first = get(h_am(1),'position');
	axes_other = get(gca,'position');
	set(h_am(1), 'position', [axes_first(1:2) axes_other(3:4)])
	axes_cbh = get(cbh,'position');
	set(cbh, 'position', [axes_cbh(1)+0.05 axes_first(2) axes_cbh(3) axes_first(4)])
	suptitle('Ghost region detection')
	set(gcf,'paperpositionmode','auto')

	h_remove = figure; set(gcf, 'position', [3 30 1250 633])
	h_af_amb_corr = tight_subplot(N_h,ceil(no_image/N_h), [.1 .1], [.1 .1], [.1 .1]); set(h_af_amb_corr([1:length(h_af_amb_corr)]>no_image), 'visible','off')
	for ii = 1:no_image
		% subplot(2,ceil(no_image/2),ii)
		axes(h_af_amb_corr(ii))
		imagesc((grid_x-center_x)/1000, (grid_y-center_y)/1000, im_pseudo(:,:,ii)); hold on
		[c_bathy, h_bathy] = contour((bathygrid_x-center_x)/1000, (bathygrid_y-center_y)/1000, bathy_map, [-300:50:0],'k--');
		axis xy equal tight
		caxis([80 170])
		set(gca,'fontsize',12, 'fontweight','normal')
		title(datestr(timestamp(ii)))
		xlim([min((grid_x-center_x)/1000) max((grid_x-center_x)/1000)])
		ylim([min((grid_y-center_y)/1000) max((grid_y-center_y)/1000)])
		if ii==1, xlabel('Easting (km)'); ylabel('Northing (km)'); cbh = colorbar; set(cbh,'fontsize',12,'fontweight','normal'); ylabel(cbh, 'Intensity'); end
		colormap(cmap)
	end
	axes_first = get(h_af_amb_corr(1),'position');
	axes_other = get(gca,'position');
	set(h_af_amb_corr(1), 'position', [axes_first(1:2) axes_other(3:4)])
	axes_cbh = get(cbh,'position');
	set(cbh, 'position', [axes_cbh(1)+0.05 axes_first(2) axes_cbh(3) axes_first(4)])
	suptitle('After ambiguity correction')
	set(gcf,'paperpositionmode','auto')

	h_f = figure; set(gcf, 'position', [3 30 1250 633])
	h_flow = tight_subplot(N_h,ceil(no_image/N_h), [.1 .1], [.1 .1], [.1 .1]); set(h_flow([1:length(h_flow)]>no_image), 'visible','off')
	for ii = 1:no_image
		% subplot(2,ceil(no_image/2),ii)
		axes(h_flow(ii))
		imagesc((grid_x-center_x)/1000, (grid_y-center_y)/1000, flow_mag(:,:,ii)); hold on
		[c_bathy, h_bathy] = contour((bathygrid_x-center_x)/1000, (bathygrid_y-center_y)/1000, bathy_map, [-300:50:0],'k--');
		axis xy equal tight
		caxis([0 15])
		set(gca,'fontsize',12, 'fontweight','normal')
		title(datestr(timestamp(ii)))
		xlim([min((grid_x-center_x)/1000) max((grid_x-center_x)/1000)])
		ylim([min((grid_y-center_y)/1000) max((grid_y-center_y)/1000)])
		if ii==1, xlabel('Easting (km)'); ylabel('Northing (km)'); cbh = colorbar; set(cbh,'fontsize',12,'fontweight','normal'); ylabel(cbh, 'Normalized flow speed'); end
		colormap(cmap)
	end
	axes_first = get(h_flow(1),'position');
	axes_other = get(gca,'position');
	set(h_flow(1), 'position', [axes_first(1:2) axes_other(3:4)])
	axes_cbh = get(cbh,'position');
	set(cbh, 'position', [axes_cbh(1)+0.05 axes_first(2) axes_cbh(3) axes_first(4)])
	suptitle([type ' Flow'])
	set(gcf,'paperpositionmode','auto')
	
	saveas(h_ghost,['../result_data/' file_prelude 'ghost_' type],'fig')
	saveas(h_ghost,['../result_data/' file_prelude 'ghost_' type],'png')
	saveas(h_ghost,['../result_data/' file_prelude 'ghost_' type],'epsc')
	
	saveas(h_remove,['../result_data/' file_prelude 'af_amb_corr_' type],'fig')
	saveas(h_remove,['../result_data/' file_prelude 'af_amb_corr_' type],'png')
	saveas(h_remove,['../result_data/' file_prelude 'af_amb_corr_' type],'epsc')
	
	saveas(h_f,['../result_data/' file_prelude 'flow_' type],'fig')
	saveas(h_f,['../result_data/' file_prelude 'flow_' type],'png')
	saveas(h_f,['../result_data/' file_prelude 'flow_' type],'epsc')
end

save([num2str(no_image) '_amb_corr.mat'],'-v7.3')

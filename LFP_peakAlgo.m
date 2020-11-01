clear;
close all;
load('LFP_OCP.mat');

step = 1;
t = -.1:step/5000:.3;

%%
LFP_OCP2 = LFP_OCP;
lowfilt = 50;
sf = 5000;
d = designfilt('lowpassiir','FilterOrder',4,'PassbandFrequency',lowfilt,'PassbandRipple',0.2,'SampleRate',sf);
for kkk=1:size(LFP_OCP2{1,1},1)
    LFP_OCP2{1,1}(kkk,:) = filtfilt(d,LFP_OCP2{1,1}(kkk,:));
end
%% Filtering
lowfilt = 30;
sf = 5000;
d = designfilt('lowpassiir','FilterOrder',4,'PassbandFrequency',lowfilt,'PassbandRipple',0.2,'SampleRate',sf);
for kkk=1:size(LFP_OCP{1,1},1)
    LFP_OCP{1,1}(kkk,:) = filtfilt(d,LFP_OCP{1,1}(kkk,:));
end

%%
%remove 50 hertz for monitor refresh rate
nFreq = [45,65];
nOrder = 4;
sf = 5000;
[bnn , ann] = butter(nOrder/2,nFreq/(sf/2),'stop');
% for kkk=1:size(LFP_OCP{1,1},1)
%     LFP_OCP{1,1}(kkk,:)=filter(bnn,ann,LFP_OCP{1,1}(kkk,:));
% end

%%
%DoenSampling
LFP_OCP1 = LFP_OCP;
LFP_OCP1{1,1} = LFP_OCP{1,1}(:,1:step:end);
LFP_OCP = LFP_OCP1;

%%
[x_size, y_size] = size(LFP_OCP{1,1});

%%
for i=1:x_size
    LFP_OCP{1,1}(i,:)=(LFP_OCP{1,1}(i,:)-min(LFP_OCP{1,1}(i,:)))/(max(LFP_OCP{1,1}(i,:))-min(LFP_OCP{1,1}(i,:)));
end

%%
peaks = zeros([x_size 4]);

% for i = 1:x_size
%     [Y_localMax, X_localMax] = findpeaks(LFP_OCP{1,1}(i:i,:),t,'threshold',0.0000038,'MinPeakDistance',0.15);
%     [Y_localMin, X_localMin] = findpeaks(-1*LFP_OCP{1,1}(i:i,:),t,'threshold',0.0000038,'MinPeakDistance',0.15);
%     peaks(i,1) = X_localMax(1);
%     peaks(i,2) = Y_localMax(1);
%     peaks(i,3) = X_localMin(1);
%     peaks(i,4) = -1*Y_localMin(1);
% end


for i = 1:x_size    
    [peaks(i,2), peaks(i,1)] = max(LFP_OCP{1,1}(i:i,500/step:1500/step));
    [peaks(i,4), peaks(i,3)] = min(LFP_OCP{1,1}(i:i,500/step:1500/step));
    peaks(i,1) = peaks(i,1)*step/5000 - 0.1;
    peaks(i,3) = peaks(i,3)*step/5000 - 0.1;
end


classify = zeros([x_size 1]);

for i = 1:x_size
    if(peaks(i,1) < peaks(i,3))     %sourse signal
        min2_y = Inf;
        min2_x = 0;
        for j = 1:y_size
            if min2_y > LFP_OCP{1,1}(i,j) && LFP_OCP{1,1}(i,j) > peaks(i,4)
                min2_y = LFP_OCP{1,1}(i,j);
                min2_x = j*step/5000 - 0.1;
            end
        end
        if min2_x < peaks(i,1)
            classify(i) = 2;
        else
            classify(i) = 1;
        end
    else                            %sink signal
        classify(i) = 2;
    end
end

c1 = 1;
c2 = 1;

for i = 1:x_size
    if classify(i) == 1
        sourceSignals(c1:c1,:) = LFP_OCP2{1,1}(i:i,:);
        sourceTitles(c1:c1,:) = LFP_OCP{1,2}(i:i,:);
        c1 = c1 + 1;
    else
        sinkSignals(c2:c2,:) = LFP_OCP2{1,1}(i:i,:);
        sinkTitles(c2:c2,:) = LFP_OCP{1,2}(i:i,:);
        c2 = c2 + 1;
    end
end

c1 = c1 - 1;
c2 = c2 - 1;

%%
rng(1);

kk1 = 2;
kk2 = 2;

idx1 = kmeans(sourceSignals(:,500/step:1000/step), kk1);
idx2 = kmeans(sinkSignals(:,500/step:1000/step), kk2);

class_count1 = zeros([kk1 1]);
class_count2 = zeros([kk2 1]);

% c = 0;
% 
% for i = 1:x_size
%     b = 0;
%     if classify(i) == 2
%         c = c + 1;
%         [Y_localMin, X_localMin] = findpeaks(-1*LFP_OCP{1,1}(i:i,:),t,'threshold',0.00001);
%         for j = 1:size(X_localMin, 2)
%             if abs(X_localMin(j) - peaks(i,3)) < 0.01
%                 if j ~= 1
%                     if abs(X_localMin(j-1) - X_localMin(j)) < 0.03 && abs(Y_localMin(j-1) - Y_localMin(j)) < 0.03
%                         b = 1;
%                         break;
%                     end
%                 end
%                 if j ~= size(X_localMin)
%                     if abs(X_localMin(j+1) - X_localMin(j)) < 0.03 && abs(Y_localMin(j+1) - Y_localMin(j)) < 0.03
%                         b = 1;
%                         break;
%                     end
%                 end
%             end
%         end
%         if b == 1
%             class2(1,c) = 1;
%             class_count2(1) = class_count2(1) + 1;
%         else
%             class2(2,c) = 1;
%             class_count2(2) = class_count2(2) + 1;
%         end
%     end
% end

for i = 1:c1
    for j = 1:kk1
        if idx1(i)==j
            class1(j,i) = 1;
            class_count1(j) = class_count1(j) + 1;
        end
    end
end

for i = 1:c2
    for j = 1:kk2
        if idx2(i)==j
            class2(j,i) = 1;
            class_count2(j) = class_count2(j) + 1;
        end
    end
end

%%

x = 12;y = 7;

for k = 1:kk1
    n = 1;
    hFig = figure;
    for i = 1:c1
        if class1(k,i) == 1
            sp_hand = subplot(x,y,n);
  
            plot(t(1:end), smooth(sourceSignals(i:i,:),1));
            
            pos1 = get(sp_hand, 'Position'); % gives the position of current sub-plot
            new_pos1 = pos1 +[0 0 0.01 0.01];
            set(sp_hand, 'Position',new_pos1); % set new position of current sub - plot
            
            line([0 0], [min(sourceSignals(i,:)) max(sourceSignals(i,:))], 'Color', [1 0 0]);
            
            title(sourceTitles(i:i,:),'fontsize',7,'Units', 'normalized', 'Position', [-0.01, +0.8, 0]);
            color = get(hFig,'Color');

            xlim([-0.1 .3]);
            ylim([min(sourceSignals(i,:))-0.01 max(sourceSignals(i,:))]+0.01);

            axis off;
            if n>fix(class_count1(k)/y)*y || ( fix(class_count1(k)/y)*y == class_count1(k) && n > (fix(class_count1(k)/y)-1)*y )
                
                ax=findobj(sp_hand,'type', 'axes');
                axis(ax,'on');
                ax.XLabel.String = 'Time';
                ax.Color = 'none';
                set(gca,'yColor','none','ytick',[],'box','off');
            else
                set(gca,'XColor',color,'YColor',color,'TickDir','out');
            end
            n = n + 1;
        end
    end
end

for k = 1:kk2
    n = 1;
    hFig = figure;
    for i = 1:c2
        if class2(k,i) == 1
            sp_hand = subplot(x,y,n);
  
            plot(t(1:end), smooth(sinkSignals(i:i,:),1));
            
            pos1 = get(sp_hand, 'Position'); % gives the position of current sub-plot
            new_pos1 = pos1 +[0 0 0.01 0.01];
            set(sp_hand, 'Position',new_pos1); % set new position of current sub - plot
            
            line([0 0], [min(sinkSignals(i,:)) max(sinkSignals(i,:))], 'Color', [1 0 0]);
            
            title(sinkTitles(i:i,:),'fontsize',7,'Units', 'normalized', 'Position', [-0.01, +0.8, 0]);
            color = get(hFig,'Color');

            xlim([-0.1 .3]);
            ylim([min(sinkSignals(i,:))-0.01 max(sinkSignals(i,:))]+0.01);

            axis off;
            if n>fix(class_count2(k)/y)*y || ( fix(class_count2(k)/y)*y == class_count2(k) && n > (fix(class_count2(k)/y)-1)*y )
                
                ax=findobj(sp_hand,'type', 'axes');
                axis(ax,'on');
                ax.XLabel.String = 'Time';
                ax.Color = 'none';
                set(gca,'yColor','none','ytick',[],'box','off');
            else
                set(gca,'XColor',color,'YColor',color,'TickDir','out');
            end
            n = n + 1;
        end
    end
end

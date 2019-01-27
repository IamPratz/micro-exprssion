clear all;
close all;
clc;
%% ��������
% 1. ��FxRadius������FyRadius���͡�TInterval������X��Y��T��İ뾶����; ���ǿ�����1,2,3��4.����ʹ�á�1���͡�3����
FxRadius = 1;
FyRadius = 1;
TInterval = 4;

% 2.��TimeLength���͡�BoderLength����ʱ��Ϳռ��еĲ��ֲ���������Ϊ�������㡣 ͨ��������TInterval��ͬ���ǡ�FxRadius���͡�FyRadius���нϴ��һ��;
TimeLength = 4;
BorderLength = 1;

% 3.��bBilinearInterpolation�������ʹ��˫���Բ�ֵ����Բ�е��ھӵ㣺1���ǣ���0�����ǣ�
bBilinearInterpolation = 1;

% 4. 59��������8�����ڵ㡣���������uniformģʽ���뽫������Ϊ0��Ȼ��������LBP
Bincount = 59; %59 / 0
NeighborPoints = [8 8 8]; % XY, XT, and YT planes, respectively
if Bincount == 0
    Code = 0;
    nDim = 2 ^ (NeighborPoints(1)); % dimensionality of basic LBP
else
    % uniform patterns for neighboring points with 8
    U8File = importdata('UniformLBP8.txt');
    BinNum = U8File(1, 1);
    nDim = U8File(1, 2); %dimensionality of uniform patterns
    Code = U8File(2 : end, :);
    clear U8File;
end

% 5. micro-expression classifier
negative = 0; positive = 1; surprise = 2;
%% read label
FileName = "..\\combined_3class_gt.csv";
FileFeature = "FeatureDecriptors_17";
FileTabel = readtable(FileName);
%% image show
height = 250;
width = 200;
Micro_Number = 11;
FileLabel = table2cell(FileTabel);
FeatureMap = [];
LabelMap = [];
subject = 'sub01';
index = 1;
for i = 1 : 442%length(FileLabel)
    fprintf("����%s������%s���ڼ���\n", subject, cell2mat(FileLabel(i,3)));
    FilePath = "..\\Data\\" + FileLabel(i,1) + "\\" + FileLabel(i,2) + "\\" + FileLabel(i,3);
    if i == 146
        subject = 's01';
    end
    if i == 310
        subject = '6';
    end
    if subject == cell2mat(FileLabel(i,2))
        fprintf("%s not save!\n", subject);
    else
        fprintf("%s save feature!\n", subject);
        FeaturePath = "..\\" + FileFeature + "\\SubjectFeatureMap_" + subject + ".mat";
        LabelPath = "..\\" + FileFeature + "\\SubjectLabelMap_" + subject + ".mat";
        save(FeaturePath, 'FeatureMap');
        save(LabelPath, 'LabelMap');
        FeatureMap = [];
        LabelMap = [];
        index = 1;
        subject = cell2mat(FileLabel(i,2));
    end

    cd (FilePath);
    a = dir('*.jpg');
    A = zeros(length(a), 1);
    for j = 1 : length(a)
        ImgName = getfield(a, {j}, 'name');
        ms = ImgName(1:end-4);
        A(j, 1) = str2num(ms);
    end
    A = int32(A);
    B = sort(A);
    
    Num_Frame = idivide(int32(length(a)), int32(Micro_Number), 'floor');
    k = 1;
    for j = 1 : Num_Frame : length(a) 
        ImgName = sprintf('%d%s', B(j,1),'.jpg');
        Imgdat = imread(ImgName);
        if size(Imgdat, 3) == 3 % if color images, convert it to gray
%             figure(1),imshow(Imgdat);
%             set(gcf,'name',ImgName);
%             pause(0.1);
            Imgdat = rgb2gray(Imgdat);
        end
        Imgdat = imresize(Imgdat, [height width]);
        [height, width] = size(Imgdat);
        if j == 1
            VolData = zeros(height, width, Micro_Number);
        end
        VolData(:, :, k) = Imgdat;
        k = k + 1;
        % imshow(Imgdat);
        % pause(0.01);   
        % fprintf(ImgName + "\n");
    end
    
    cd ('..\\..\\..\\..\\micro-expression');
    % call LBPTOP
    
    eyes_h = 100; eyes_w = 200;
    nose_h = 150; nose_w = 150;
    VolData_eyes = VolData(1: 100, 1: 200, :);
    VolData_nose = VolData(100: 250, 25: 175, :);
    
    batch = 1;
    batchSize_eyes_h = 2; batchSize_eyes_w = 4;
    batch_eyes_h = eyes_h / batchSize_eyes_h; bach_eyes_w = eyes_w / batchSize_eyes_w;
    for batch_h = 1 : batchSize_eyes_h
        for batch_w = 1 : batchSize_eyes_w
            batch_h_top = batch_eyes_h * (batch_h - 1) + 1;
            batch_h_battom = batch_eyes_h * (batch_h - 1) + batch_eyes_h;
            batch_w_top = bach_eyes_w * (batch_w - 1) + 1;
            batch_w_battom = bach_eyes_w * (batch_w - 1) + bach_eyes_w;
            batch_VolData = VolData_eyes(batch_h_top: batch_h_battom, batch_w_top:batch_w_battom,:);
            
            %fprintf("ͼ���ӿռ����꣺%d��%d��%d��%d\n", batch_h_top, batch_h_battom, batch_w_top, batch_w_battom);
            Histogram = LBPTOP(batch_VolData, FxRadius, FyRadius, TInterval, NeighborPoints, TimeLength, BorderLength, bBilinearInterpolation, Bincount, Code);
            Histogram_result = Histogram(:)';
            batch_end = batch + Bincount * 3 - 1;
            FeatureMap(index, batch : batch_end) = Histogram_result; 
            
            img = uint8(batch_VolData(:,:,1));
            m = batch_w + (batch_h - 1) * batchSize_eyes_w;
%             figure(2),
%             subplot(batchSize_eyes_h, batchSize_eyes_w, m),imshow(img);
            %fprintf("batch_h:%d��batch_w:%d��m:%d\n", batch_h, batch_w, m);
            pause(0.01);
            batch = batch + Bincount * 3;
        end
    end
    
    batchSize_nose = 3;
    batch_nose_h = nose_h / batchSize_nose; bach_nose_w = nose_w / batchSize_nose;
    for batch_h = 1 : batchSize_nose
        for batch_w = 1 : batchSize_nose
            batch_h_top = batch_nose_h * (batch_h - 1) + 1;
            batch_h_battom = batch_nose_h * (batch_h - 1) + batch_nose_h;
            batch_w_top = bach_nose_w * (batch_w - 1) + 1;
            batch_w_battom = bach_nose_w * (batch_w - 1) + bach_nose_w;
            batch_VolData = VolData_nose(batch_h_top: batch_h_battom, batch_w_top:batch_w_battom,:);
            
            m = batch_w + (batch_h - 1) * batchSize_nose;
            
            if m ~= 2
                %fprintf("ͼ���ӿռ����꣺%d��%d��%d��%d\n", batch_h_top, batch_h_battom, batch_w_top, batch_w_battom);
                Histogram = LBPTOP(batch_VolData, FxRadius, FyRadius, TInterval, NeighborPoints, TimeLength, BorderLength, bBilinearInterpolation, Bincount, Code);
                Histogram_result = Histogram(:)';
                batch_end = batch + Bincount * 3 - 1;
                FeatureMap(index, batch : batch_end) = Histogram_result;
            
            
%             img = uint8(batch_VolData(:,:,1));
%             m = batch_w + (batch_h - 1) * batchSize_nose;
%             figure(3),
%             subplot(batchSize_nose,batchSize_nose, m),imshow(img);
%             fprintf("batch_h:%d��batch_w:%d��m:%d\n", batch_h,batch_w, m);
%             pause(0.01);
                batch = batch + Bincount * 3;
            end
        end
    end
    
    LabelMap(index,:) = int8(cell2mat(FileLabel(i,4)));    
%     figure(4),subplot(1,1,1),bar(FeatureMap(index,:),1);
%     pause(0.01); 
    index = index + 1;
    if i == 145 || i == 309 || i == 442
        fprintf("%s save feature!\n", subject);
        FeaturePath = "..\\" + FileFeature + "\\SubjectFeatureMap_" + subject + ".mat";
        LabelPath = "..\\" + FileFeature + "\\SubjectLabelMap_" + subject + ".mat";
        save(FeaturePath, 'FeatureMap');
        save(LabelPath, 'LabelMap');
        FeatureMap = [];
        LabelMap = [];
        index = 1;
        fprintf("end!\n");
    end
    pause(1);   
end
%%
subplot(1,1,1),bar(FeatureMap(1,:));

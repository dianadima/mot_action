function [features, layer_labels, cnn_models] = extract_cnn_features(nettype,imagedata, selected_layers)
%extract layer activations for image set using pre-trained DNNs
%input: nettype: 'alexnet', 'vgg19', 'resnet50', 'resnet101'
%       imagedata: path to directory (will be read in alphabetical order)
%       or 4D matrix (h x w x c x N)
%output: features (layer activations reshaped into row vectors)
%        layer_labels (names of layers extracted)
%        cnn_models (RDMs based on feature Euclidean distances)
%
% DC Dima 2020 (diana.c.dima@gmail.com)

%defines the layers that will be extracted for each type of network - normally we want one from each 'block'
switch nettype
    case 'alexnet'
        net = alexnet;
        layers = {'pool1','pool2','relu3','relu4','pool5','fc6','fc7','fc8'};
        layer_labels = {'Conv1', 'Conv2', 'Conv3', 'Conv4', 'Conv5', 'FC6', 'FC7', 'FC8'};
    case 'vgg19'
        net = vgg19;
        layers = {'conv1_2','conv2_2','conv3_4','conv4_4','conv5_4','fc6','fc7','fc8'};
        layer_labels = {'Conv1', 'Conv2', 'Conv3', 'Conv4', 'Conv5', 'FC6', 'FC7', 'FC8'};
    case 'resnet50'
        net = resnet50;
        layers = {'conv1','res2c_branch2c','res3d_branch2c','res4f_branch2c','res5c_branch2c','fc1000'};
        layer_labels = {'Conv1', 'Block1', 'Block2', 'Block3', 'Block4', 'FC1000'};
    case 'resnet101'
        net = resnet101;
        layers = {'conv1','res2c_branch2c','res3d_branch2c','res4f_branch2c','res5c_branch2c','fc1000'};
        layer_labels = {'Conv1', 'Block1', 'Block2', 'Block3', 'Block4', 'FC1000'};
end

%% if we want a subset of layers
if ~isempty(selected_layers)
    l = cell(numel(selected_layers),1);
    for il = 1:numel(selected_layers)
        l{il} = layer_labels{contains(layers,selected_layers{il})};
    end
    layers = selected_layers;
    layer_labels = l;
end

%% prepare images using imageDatastore or numeric format for input

inputsize = net.Layers(1).InputSize; %image size required by DNN

if ischar(imagedata) %if input is a path to a directory, use imageDatastore to process all images at once
    imdata = imageDatastore(imagedata); %path
    numimg = length(imdata.Files);
    imdata = augmentedImageDatastore(inputsize, imdata, 'ColorPreprocessing','gray2rgb');
else
    numimg = size(imagedata,4); %if input is a 4D array, process images one by one
    imdata = nan(inputsize(1), inputsize(2), 3, numimg);
    for img = 1:size(imagedata,4)
        imdata(:,:,:,img) = imresize(imagedata(:,:,:,img), [inputsize(1) inputsize(2)]); 
    end

end

%% extract features for each layer

numlayers = numel(layers);

%this will store the feature maps for each layer
features = cell(1,numlayers);

%this will store an RDM based on the layer features (in case we want to do RSA)
cnn_models = nan(numimg*(numimg-1)/2,numlayers);

for il = 1:numlayers
    
    fprintf('\nExtracting features for layer %d...', il);
    
    layer = layers{il};
    feat = activations(net, imdata, layer, 'OutputAs','rows');
    
    %%for features output as channels
    %sz = size(feat); 
    %feat = reshape(feat, [prod(sz(1:3)) numimg])';
    
    cnn_models(:,il) = pdist(feat);
    features{il} = feat;
    
    
end

%% if needed - final prediction step
% the below shows the final label predicted by the network for the test
% images - normally we don't need this (and it's inaccurate)

% [YPred,probs] = classify(net,imdata);
% figure
% %plot first 50 images
% for i = 1:50
%     subplot(5,10,i)
%     if ischar(imagedata)
%         I = readimage(imdata,i);
%     else
%         I = imdata(:,:,:,i);
%     end
%     imshow(I)
%     label = YPred(i);
%     title(string(label) + ", " + num2str(100*max(probs(i,:)),3) + "%");
% end

end

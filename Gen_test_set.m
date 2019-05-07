function [testset] = Gen_test_set(image,setting, EdgeTemplate, LayoutTemplate, PaletteDictionaty)

 featureLength = 24; %%%24
    N = length(setting.test_list);
    testset = zeros(1,featureLength);
    

        %image = imread(img);
        %size(image)
       %image=reshape(image,[1080,1080,3])
       [h,w,nch]=size(image);
       if(nch<3)
            timg=zeros(h,w,3);
            timg(:,:,1)=image;
            timg(:,:,2)=image;
            timg(:,:,3)=image;
            image=timg;
       end    
       image = imresize(image,[setting.proc_height,setting.proc_width],'bilinear');
       hsv_image = rgb2hsv(image);
       

       [fea_color, fea_HSVcount] = fColor(hsv_image, nch, setting, PaletteDictionaty);
       [fea_comp_layout, fea_texture_layout] = fComp_Layout(hsv_image, setting, LayoutTemplate);
       [fea_comp_edge, fea_texture_edge] = fComp_Edge(hsv_image, setting, EdgeTemplate);
       fea_blur = fBlur(image,500);
       fea_dark = fDarkChannel(image);
       fea_const_rgb = fContrast_rgb(image);
       fea_const_gray = fContrast_gray(image);
       fea = [fea_color,fea_comp_layout,fea_comp_edge,fea_texture_layout,fea_texture_edge,fea_blur,fea_dark,fea_const_rgb,fea_const_gray,fea_HSVcount];
       %fea = [fea_comp_edge,fea_texture_edge,fea_blur,fea_dark,fea_const_rgb,fea_const_gray];
       testset(1,:) = fea;
  
end






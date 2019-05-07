function  SL_motion_detector(soglia,delta_tresh,percorso,percL,percH)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%La function 'SL_motion_detect' è una funzione che data una serie di frames
%analizza e determina automaticamente se è presente movimento nella scena
%ponendo l'animale mosso in un riquadro verde.L'algoritmo che implementa è
%un algoritmo di motion detection che sfrutta un approccio geometrico e per
%rilevare sia lo spostamento,senza quindi utilizzare algoritmi nè di block 
%matching, nè di flusso ottico , molto complessida implementare nonchè
%costosi dal punto di vista computazionale.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Leggi i frame dalla cartella 

fileFolder = fullfile(percorso); 
dirOutput = dir(fullfile(fileFolder,'*.jpg'));
listaFrames = struct2cell(dirOutput);


% Leggi il primo frame dall'array e prendilo come background di origine
% numero zero
sfondo00=listaFrames{1,1};

% Leggi il frame di background iniziale e convertilo da RGB in scala di grigi
sfondoPrec = imread(sfondo00);
backInit=(sfondoPrec);
sfondoPrec = rgb2gray(sfondoPrec);

% Acquisisci informazioni sul numero di righe e colonne del background
Info = imfinfo(sfondo00); 
LFrame = Info.Width; 
HFrame = Info.Height;

% inizializzo una memoria per contenere coordinate del centroide dei vari
% blob 
centroCoord=cell(1,length(listaFrames)-1);
memFrameLoc=cell(1,length(listaFrames)-1);
memCrop=cell(1,length(listaFrames)-1);
LMEM=cell(1,length(listaFrames)-1);
HMEM=cell(1,length(listaFrames)-1);

% Scandisci tutti gli elementi della lista
 for i=2:1:length(listaFrames)-1
     
% inizializzo maschere binarie di aggiornamento delle condizioni di
% background dovute a cambiamenti di iluminazione o spostamento di animali
% e/o vegetazione.
 mascheraSfondo = (ones(HFrame,LFrame));
 
      %leggi frame corrente nella lista
      frameCorrente = imread(listaFrames{1,i});
      frameCorrente = rgb2gray(frameCorrente);
      
      %fai differenza in valore assoluto tra frame corrente e sfondo
      %corrente
       deltaSfondo = imabsdiff(frameCorrente,sfondoPrec) ;
      
      %aggiorna lamaschera binaria con punti (black) in cui la differenza
      %è zero
      mascheraSfondo(find(deltaSfondo<1))=0;
      
      %complementare del coefficiente di variabilità dello sfondo data
      %dalla media dei valori nella maschera binaria precedente
      costAlfa=(1-mean2(mascheraSfondo));
      
      %formula di aggiornamento del background
      sfondoUp = ((costAlfa.*sfondoPrec)+((1-costAlfa).*frameCorrente));
      
      %aggiorna sfondo precedente
      sfondoPrec=(sfondoUp);
      
      %fai la sottrazione tra frame corrente e sfondo adattato corrente
      frameMenoSfondo=imabsdiff(frameCorrente,sfondoPrec) ;
     
      %applico sogliatura iterativa con algoritmo di Gonzales-Woods
      T = 0.4*( double(min(frameMenoSfondo(:))) + ...
          double(max(frameMenoSfondo(:))) );
      done = false;
      while ~done
      g = frameMenoSfondo>=T;
      Tnext = 0.4*( mean(frameMenoSfondo(g)) + mean(frameMenoSfondo(~g)) );
      done = abs( T-Tnext )<0.4;
      T = Tnext;
      end
      
      %applico opeazioni morfologiche per modellare al meglio i blob...
      %segmentati 
      masch1 = strel('disk',3);
      dilata = imdilate(g,masch1);
      masch2 = strel('square',3);        
      erodi = imerode(dilata,masch2);
      img_bin = imfill(erodi,'holes');  
     
 
      %calcola occorrenze di pixel bianchi nell'immagine binaria
      presenze = calcolaOccorrenze(img_bin);

      %fai analisi dei blobs
      blobAnalysis = vision.BlobAnalysis('BoundingBoxOutputPort', true,...
            'AreaOutputPort', false, 'CentroidOutputPort',false,...
            'MinimumBlobArea', 150);
      bbox = step(blobAnalysis, img_bin);
      frame=imread(listaFrames{1,i});
      numOgg = size(bbox, 1);

        %se pixel bianchi sono sopra soglia vai avalutare l'intensita media
        %tra blob corrente e stesso punto nello sfondo statico
        if presenze>soglia
            
            [crop,img_bin2,img_Blob] = ValutaIntMedia(frame,bbox,numOgg,backInit,delta_tresh);
            %calcola centroide blob
            [width,high,centroideRect]=calcolaCentroideRect(img_Blob);
  %          if width>perc
            LMEM{1,i}=width;
            HMEM{1,i}=high;
            %memorizza coord centroide e frame corrente
            centroCoord{1,i}=centroideRect;
            memFrameLoc{1,i}=img_bin2;
            memCrop{1,i}=crop;
 %           end
             if ~isempty(centroideRect)
                 %plotta punti centroide
                 %hold on
                 %plot(centroideRect(1,1),centroideRect(1,2),...
                   % 'g.','MarkerSize',20)
             end
        else
            %elimina blobs inferiri a una certa dimensione nell immagine
            %binaria
            img_bin = bwareaopen(img_bin, 400);
            
            %calcola centroide blobs
            [centroide]=calcolaCentroide(img_bin);
            %memorizza coord
            centroCoord{1,i}=centroide;
            
            %rianalizza  blob e plotta nuova immagine di oggetto in
            %movimento
            bbox = step(blobAnalysis, img_bin);
            if ~isempty(bbox)
            L=bbox(1,3);
            H=bbox(1,4);
            LMEM{1,i}=L;
            HMEM{1,i}=H;
            
%            if L>perc
            frame=imread(listaFrames{1,i});
            result = insertShape(frame, 'Rectangle', bbox, 'Color', 'green');
            memFrameLoc{1,i}=result;
            
            % calcola l'area del blob più grande e memorizzala per
            % scegliere il blob più probabile
            areas=zeros(size(bbox,1),1);
            for z=1:size(bbox,1)
            
            A=bbox(z,3)*bbox(z,4);
            areas(z,1)=A;
            end
            [M,I]=max(areas(:));
            rbbox=bbox(I,1:4);
            
            
            crop_img=imcrop(frame,rbbox);
            memCrop{1,i}=crop_img;
            else
                memCrop{1,i}=frame;
            end
%            end
            if ~isempty(centroide)
               %plotta punti centroide
               %hold on
               %plot(centroide(1,1),centroide(1,2),'r.','MarkerSize',20)
            end
        end
 end
 
 [centroCoord]=calcolaDistEuclidea(centroCoord,memFrameLoc,percL,percH,LMEM,HMEM,memCrop);
end

function presenze = calcolaOccorrenze(img_bin)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% La funzione CalcolaOccorrenze , conta il numero di occorrenze di una
% matrice di valoridiversi da zero.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
occ=0;

%calcolo occorrenze
[righe,col]=size(img_bin);
    for m = 1:righe
        for n = 1:col
      if img_bin(m,n) ~= 0  
        occ = occ + 1; 
      end
        end
    end
presenze=occ;

end

function [crop,img_bin2,img_Blob] = ValutaIntMedia(frame,bbox,numOgg,backInit,delta_tresh)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%la funzione valuta l 'intensita media nei punti dei blob nel frame
%corrente e nel background statico allo stesso posto.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
global memBox
global rect
%global crop

     for n=1:numOgg
     % n- esima riga della bounding box    
     rigaBBOX=bbox(n,1:4);
     
     ritaglioFrame=imcrop(frame,[rigaBBOX]);
     ritaglioSfondo=imcrop(backInit,[rigaBBOX]);
     
     %calcola media dei valori nei blob ritagliati 
     mediaFrame=mean2(ritaglioFrame);
     mediaSfondo=mean2(ritaglioSfondo);
     deltaMedia=mediaFrame-mediaSfondo;

     %se intensita è superiore a soglia allora qualcosa è in movimento
     %traccia rettangolo sull'oggetto trovato.
     if  deltaMedia>delta_tresh                                               

         rect=insertShape(frame, 'Rectangle', rigaBBOX , 'Color', 'green');
         memBox=rigaBBOX;
         crop=imcrop(frame,rigaBBOX);
         break
         %altrimenti non hai trovato niente e mostra il frame cosi com' è
     else
         rect=frame;
         crop=frame;
        
     end
     end
     img_bin2=rect;
     img_Blob=memBox;
end

function [centroide]=calcolaCentroide(img_bin)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%la funzione calcola il centroide di un blob qualsiasi su un immagine
%binaria.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

blobAnalysis = vision.BlobAnalysis('BoundingBoxOutputPort', true,...
            'AreaOutputPort', true, 'CentroidOutputPort',true,...
            'MinimumBlobArea', 150);
[areas, centroids] = step(blobAnalysis,img_bin);
[maxValue, linearIndexesOfMaxes] = max(areas(:));
[rMax ,cMax] = find(areas == maxValue);
centroide=[centroids(rMax,cMax),centroids(rMax,cMax+1)];
    
end

function [width,high,centroideRect]=calcolaCentroideRect(img_Blob)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%la funzione calcola il centroide di un rettangolo.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%if size(img_Blob)~=[0,0]
x=img_Blob(1,1);
y=img_Blob(1,2);
width=img_Blob(1,3);
high=img_Blob(1,4);

Xcoord=x+(0.5*width);
Ycoord=y+(0.5*high);

centroideRect=[Xcoord,Ycoord];
%end
end

function [centroCoord]=calcolaDistEuclidea(centroCoord,memFrameLoc,percL,percH,LMEM,HMEM,memCrop)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%La funzione calcola la distanza euclidea tra due punti a partire dalle
%coordinatex,y dei due punti
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

cartella_detect = './detected_Frames/';
%cartella_crop = './detected_crop/';

if exist ('detected_Frames') 
   rmdir detected_Frames s
   mkdir detected_Frames
else
   mkdir detected_Frames
end
NOdet=0;
det=0;
for k=1:length(centroCoord)
    if isempty(centroCoord{1,k})
       centroCoord{1,k}=[0,0]; 
    end
end

for i=1:1:(length(centroCoord)-1)
    %prendi le coordinate dell'elemento del vettore
    C1=centroCoord{1,i};
    C2=centroCoord{1,i+1};
    
    %prendi la coordinata x e y del primo punto
    X1=C1(1,1);
    Y1=C1(1,2);
    
    %prendi la coordinata x e y del secondo punto
    X2=C2(1,1);
    Y2=C2(1,2);

    %calcola la distanza euclidea tra i due punti
    distanzaEuclidea=sqrt(double(((X2-X1).^2)+((Y2-Y1).^2)));
    
    if  distanzaEuclidea ~= 0
        if (LMEM{1,i}>percL & HMEM{1,i}>percH) 
        fprintf('ANIMAL MOTION DETECT! \n')
         %imshow(memFrameLoc{1,i})
         det=det+1;
         
         if (~isempty(memCrop{1,i}))
             fn = num2str(i);
             temp = '0000';
             fn = [temp(1:end-length(fn)) fn];
             %fn = temp(length(fn));
             fname = [cartella_detect '_crop' fn '.jpg'];
            % imshow(memCrop{1,i})
             imwrite(memCrop{1,i},fname,'jpg');
             
        % baseFileName = sprintf('%d.jpg', i); 
        % fullFileName = fullfile(cartella_detect, baseFileName); 
        % imwrite(memCrop{1,i}, fullFileName);
         end
         
         if (~isempty(memFrameLoc{1,i}))
             gn = num2str(i);
             %c=2;
             %c=num2str(c);
             temp = '0000';
             gn = [temp(1:end-length(gn)) gn];
             %gn = temp(gn);
             fname = [cartella_detect '_image' gn '.jpg'];
             imwrite(memFrameLoc{1,i},fname,'jpg');
         %baseFileName = sprintf('%d.jpg', i+1); 
         %fullFileName = fullfile(cartella_detect, baseFileName); 
         %imwrite(memFrameLoc{1,i}, fullFileName);
         end
         end
         
    else
        fprintf('NO MOTION DETECTED \n')
        %imshow(memFrameLoc{1,i})
        NOdet=NOdet+1;
    end
end
fprintf('Frames Detected ')
fprintf('%d  \n', det)
fprintf('No Frames Detected ')
fprintf('%d  \n', NOdet)
end


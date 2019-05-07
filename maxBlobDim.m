function [LTot,HTot] = maxBlobDim( soglia,delta_tresh,percorso )

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
%larghBlob=cell(1,length(listaFrames)-1);
memFrameLoc=cell(1,length(listaFrames)-1);
larghBlob=(zeros(1,length(listaFrames)-1));
altBlob=(zeros(1,length(listaFrames)-1));

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
      %larghezza=bbox(1,3);
      
      frame=imread(listaFrames{1,i});
      numOgg = size(bbox, 1);

        %se pixel bianchi sono sopra soglia vai avalutare l'intensita media
        %tra blob corrente e stesso punto nello sfondo statico
        if presenze>soglia
            
            [img_bin2,img_Blob] = ValutaIntMedia(frame,bbox,numOgg,backInit,delta_tresh);
            %calcola centroide blob
            [width,high,centroideRect]=calcolaCentroideRect(img_Blob);
            %memorizza coord centroide e frame corrente
            larghBlob(1,i)=width;
            altBlob(1,i)=high;
            %memFrameLoc{1,i}=img_bin2;
            
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
           % [centroide]=calcolaCentroide(img_bin);
            %memorizza coord
           % larghBlob{1,i}=centroide;
            
            %rianalizza  blob e plotta nuova immagine di oggetto in
            %movimento
            
            bbox = step(blobAnalysis, img_bin);
            
            if(~isempty(bbox))
            largh=bbox(1,3);
            larghBlob(1,i)=largh;
            alt=bbox(1,4);
            altBlob(1,i)=alt;
            end
            frame=imread(listaFrames{1,i});
            result = insertShape(frame, 'Rectangle', bbox, 'Color', 'green');
            memFrameLoc{1,i}=result;

            %if ~isempty(centroide)
               %plotta punti centroide
               %hold on
               %plot(centroide(1,1),centroide(1,2),'r.','MarkerSize',20)
            %end
        end
 end
 %a=cell2mat(larghBlob);
LTot=max(larghBlob(:));
HTot=max(altBlob(:));
%LTot=max([larghBlob{1,:}]);
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

function [img_bin2,img_Blob] = ValutaIntMedia(frame,bbox,numOgg,backInit,delta_tresh)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%la funzione valuta l 'intensita media nei punti dei blob nel frame
%corrente e nel background statico allo stesso posto.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
global memBox
global rect

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
         break
         %altrimenti non hai trovato niente e mostra il frame cosi com' è
     else
         rect=frame;
        
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
